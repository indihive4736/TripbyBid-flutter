import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/theme/app_theme.dart';
import 'package:tripbybid/features/payments/domain/entities/checkout.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_detail.dart';
import 'package:tripbybid/features/trips/presentation/detail/trip_detail_cubit.dart';
import 'package:tripbybid/features/trips/presentation/detail/trip_detail_view.dart';

import '../../trips_fakes.dart';
import 'detail_fakes.dart';

void main() {
  late FakeTripsRepository trips;
  late FakePaymentGateway gateway;
  late TripDetailCubit cubit;

  Future<void> pumpDetail(WidgetTester tester, TripDetail detail) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 2600 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    trips = FakeTripsRepository()..detailResult = Ok(detail);
    gateway = FakePaymentGateway();
    cubit = buildDetailCubit(trips, FakePaymentsRepository(), gateway);
    await cubit.load(DetailFixtures.requestId);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const TripDetailView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  tearDown(() => cubit.close());

  testWidgets('bids in: lists the offers and accepts the selected agent', (
    tester,
  ) async {
    await pumpDetail(tester, DetailFixtures.bidsIn());

    expect(find.text('2 bids · pick one'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('AirTrek India'), findsOneWidget);
    expect(find.text('SkyWays Travel'), findsOneWidget);
    expect(find.text('LOWEST'), findsOneWidget);
    expect(find.text('Accept AirTrek · ₹17,999'), findsOneWidget);

    await tester.tap(find.text('SkyWays Travel'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Accept SkyWays · ₹18,450'), findsOneWidget);
  });

  testWidgets('payment due: shows the fare hold countdown and Pay', (
    tester,
  ) async {
    await pumpDetail(tester, DetailFixtures.paymentDue());

    expect(find.text('Payment due'), findsOneWidget);
    expect(find.textContaining('Fare held for'), findsOneWidget);
    expect(find.text('Pay ₹17,999'), findsOneWidget);
    expect(find.text('Fare breakdown'), findsOneWidget);
    expect(find.text('TripByBid fee'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Fare held for'), findsOneWidget);
  });

  testWidgets('completed: offers to rate the agent', (tester) async {
    await pumpDetail(tester, DetailFixtures.completed());

    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Rate AirTrek'), findsOneWidget);
    expect(find.text('Manage booking'), findsOneWidget);
  });

  testWidgets('switching tabs shows the timeline and the documents', (
    tester,
  ) async {
    await pumpDetail(tester, DetailFixtures.booked());

    expect(find.text('Message agent'), findsOneWidget);

    await tester.tap(find.text('Timeline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Request posted'), findsOneWidget);
    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);

    await tester.tap(find.text('Docs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('E-ticket'), findsOneWidget);
    expect(find.text('Available on the web dashboard'), findsOneWidget);
  });

  testWidgets('pay sheet: closing the checkout keeps the sheet open', (
    tester,
  ) async {
    await pumpDetail(tester, DetailFixtures.paymentDue());
    gateway.outcome = GatewayOutcome.cancelled;

    await tester.tap(find.text('Pay ₹17,999'));
    await tester.pumpAndSettle();
    expect(find.text('Pay securely'), findsOneWidget);
    expect(find.text('To AirTrek India'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Pay ₹17,999'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(gateway.opened, 1);
    expect(find.text('Payment cancelled'), findsOneWidget);
    expect(find.text('Pay securely'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('rate sheet: rating turns the action into book again', (
    tester,
  ) async {
    await pumpDetail(tester, DetailFixtures.completed());

    await tester.tap(find.text('Rate AirTrek'));
    await tester.pumpAndSettle();
    expect(find.text('Rate AirTrek India'), findsOneWidget);

    await tester.tap(find.byTooltip('5 stars'));
    await tester.pump();
    expect(find.text('Excellent!'), findsOneWidget);

    await tester.tap(find.text('Submit rating'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(trips.calls.last, 'rateAgent:booking-1:5');
    expect(find.text('Rate AirTrek India'), findsNothing);
    expect(find.text('Book this trip again'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
