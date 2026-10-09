import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/theme/app_theme.dart';
import 'package:tripbybid/features/auth/domain/entities/user.dart';
import 'package:tripbybid/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:tripbybid/features/trips/domain/usecases/get_active_bids_usecase.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';
import 'package:tripbybid/features/trips/presentation/home/home_cubit.dart';
import 'package:tripbybid/features/trips/presentation/home/home_view.dart';

import '../../../notifications/notifications_fakes.dart';
import '../../trips_fakes.dart';

void main() {
  const user = User(
    id: 'u-1',
    email: 'asha@example.com',
    name: 'Asha Rao',
    role: UserRole.traveler,
    verified: true,
  );

  late FakeTripsRepository trips;
  late FakeNotificationsRepository notifications;
  late HomeCubit cubit;

  setUp(() {
    trips = FakeTripsRepository();
    notifications = FakeNotificationsRepository();
    cubit = HomeCubit(
      getMyTrips: GetMyTripsUseCase(trips),
      getActiveBids: GetActiveBidsUseCase(trips),
      getUnreadCount: GetUnreadCountUseCase(notifications),
      now: () => DateTime(2026, 10, 10),
    );
  });

  tearDown(() => cubit.close());

  // The hero's live dot animates forever, so pump frames instead of settling.
  Future<void> pump(WidgetTester tester) async {
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(
          value: cubit,
          child: const HomeView(user: user),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('features a trip whose payment is due', (tester) async {
    trips.myTripsResult = Ok([
      TripFixtures.request(id: 'due-0000-1', status: 'payment_pending'),
    ]);
    notifications.unreadResult = const Ok(2);
    await pump(tester);

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('PAY TO CONFIRM'), findsOneWidget);
    expect(find.text('Payment due'), findsOneWidget);
    expect(find.text('Pay to confirm'), findsOneWidget);
    expect(find.text('BOM'), findsOneWidget);
    expect(find.text('DXB'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.byTooltip('Notifications, 2 unread'), findsOneWidget);
  });

  testWidgets('shows the quick post tiles and stats', (tester) async {
    trips.myTripsResult = Ok([
      TripFixtures.request(
        status: 'completed',
        booking: TripFixtures.booking(status: 'completed', price: 6998),
      ),
    ]);
    await pump(tester);

    for (final label in ['Flight', 'Train', 'Hotel']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Post request'), findsNWidgets(3));
    expect(find.text('Total spent'), findsOneWidget);
    expect(find.text('₹6,998'), findsOneWidget);
    expect(find.text('Trips booked'), findsOneWidget);
    // Nothing to feature: the hero invites a first request.
    expect(find.text('Post a request'), findsOneWidget);
    expect(find.text('Live bids'), findsNothing);
  });

  testWidgets('lists live bids with the best offer', (tester) async {
    trips
      ..myTripsResult = Ok([TripFixtures.request(bidsCount: 3)])
      ..activeBidsResult = Ok([TripFixtures.bid(price: 18000)]);
    await pump(tester);

    expect(find.text('Live bids'), findsOneWidget);
    expect(find.text('Best offer'), findsOneWidget);
    expect(find.text('₹18,000'), findsOneWidget);
    expect(find.text('−10%'), findsOneWidget);
  });

  testWidgets('lays out at phone width with large text', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    trips
      ..myTripsResult = Ok([
        TripFixtures.request(id: 'due-0000-1', status: 'payment_pending'),
        TripFixtures.request(bidsCount: 12, budget: 125000),
      ])
      ..activeBidsResult = Ok([TripFixtures.bid(price: 99999)]);
    await pump(tester);

    expect(tester.takeException(), isNull);
  });
}
