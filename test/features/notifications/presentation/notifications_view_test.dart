import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/theme/app_theme.dart';
import 'package:tripbybid/features/notifications/domain/entities/app_notification.dart';
import 'package:tripbybid/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:tripbybid/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:tripbybid/features/notifications/presentation/widgets/notifications_view.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';

import '../../trips/trips_fakes.dart';
import '../notifications_fakes.dart';

void main() {
  late FakeNotificationsRepository repository;
  late NotificationsCubit cubit;
  final now = DateTime(2026, 10, 10, 12);

  setUp(() {
    repository = FakeNotificationsRepository();
    cubit = NotificationsCubit(
      getNotifications: GetNotificationsUseCase(repository),
      markRead: MarkNotificationReadUseCase(repository),
      markAllRead: MarkAllNotificationsReadUseCase(repository),
      getMyTrips: GetMyTripsUseCase(FakeTripsRepository()),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(
          value: cubit,
          child: NotificationsView(now: now),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('groups notifications by day', (tester) async {
    repository.pages[1] = Ok(
      NotificationPage([
        NotificationFixtures.notification(createdAt: now),
        NotificationFixtures.notification(
          id: 'n-2',
          title: 'Payment Successful',
          type: 'payment_received',
          isRead: true,
          createdAt: DateTime(2026, 10, 9, 18),
        ),
        NotificationFixtures.notification(
          id: 'n-3',
          title: 'Ticket uploaded',
          type: 'ticket_uploaded',
          isRead: true,
          createdAt: DateTime(2026, 9, 20),
        ),
      ], hasMore: false),
    );
    await pump(tester);

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('EARLIER'), findsOneWidget);
    expect(find.text('Payment Successful'), findsOneWidget);
  });

  testWidgets('tapping an unread notification marks it read', (tester) async {
    repository.pages[1] = Ok(
      NotificationPage([
        NotificationFixtures.notification(
          title: 'Trip reminder',
          type: 'system',
          referenceType: null,
          referenceId: null,
          createdAt: now,
        ),
      ], hasMore: false),
    );
    await pump(tester);
    expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);

    await tester.tap(find.text('Trip reminder'));
    await tester.pump();

    expect(repository.calls, contains('markRead:n-1'));
    expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
  });

  testWidgets('shows the caught-up state when empty', (tester) async {
    repository.pages[1] = const Ok(NotificationPage([], hasMore: false));
    await pump(tester);

    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('lays out at phone width with large text', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    repository.pages[1] = Ok(
      NotificationPage([
        NotificationFixtures.notification(createdAt: now),
      ], hasMore: true),
    );
    await pump(tester);

    expect(tester.takeException(), isNull);
  });
}
