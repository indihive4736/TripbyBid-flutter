import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/theme/app_theme.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';
import 'package:tripbybid/features/trips/presentation/list/trip_list_card.dart';
import 'package:tripbybid/features/trips/presentation/list/trips_list_cubit.dart';
import 'package:tripbybid/features/trips/presentation/list/trips_view.dart';

import '../../trips_fakes.dart';

void main() {
  late FakeTripsRepository repository;
  late TripsListCubit cubit;

  setUp(() {
    repository = FakeTripsRepository();
    cubit = TripsListCubit(getMyTrips: GetMyTripsUseCase(repository));
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const TripsView()),
      ),
    );
    await tester.pump();
  }

  testWidgets('segments filter the trip cards', (tester) async {
    repository.myTripsResult = Ok([
      TripFixtures.request(id: 'a1', bidsCount: 3),
      TripFixtures.request(
        id: 'p1',
        type: TripType.hotel,
        status: 'completed',
        booking: TripFixtures.booking(status: 'completed', price: 4200),
      ),
    ]);
    await pump(tester);

    expect(find.byType(TripListCard), findsOneWidget);
    expect(find.text('3 bids'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);

    await tester.tap(find.text('Past'));
    await tester.pump();
    expect(find.byType(TripListCard), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('₹4,200'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pump();
    expect(find.byType(TripListCard), findsNWidgets(2));
  });

  testWidgets('shows the empty state for a segment', (tester) async {
    repository.myTripsResult = const Ok([]);
    await pump(tester);

    expect(
      find.text('No active trips — post your first request'),
      findsOneWidget,
    );
    expect(find.text('Post a request'), findsOneWidget);
  });

  testWidgets('lays out at phone width with large text', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    repository.myTripsResult = Ok([
      TripFixtures.request(status: 'awaiting_agent', budget: 125000),
      TripFixtures.request(id: 'b2', bidsCount: 12),
    ]);
    await pump(tester);

    expect(tester.takeException(), isNull);
  });
}
