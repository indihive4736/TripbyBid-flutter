import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/theme/app_theme.dart';
import 'package:tripbybid/features/payments/domain/usecases/payment_usecases.dart';
import 'package:tripbybid/features/profile/domain/usecases/profile_usecases.dart';
import 'package:tripbybid/features/profile/presentation/bloc/edit_profile_cubit.dart';
import 'package:tripbybid/features/profile/presentation/bloc/notification_settings_cubit.dart';
import 'package:tripbybid/features/profile/presentation/bloc/payment_history_cubit.dart';
import 'package:tripbybid/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:tripbybid/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:tripbybid/features/profile/presentation/pages/help_page.dart';
import 'package:tripbybid/features/profile/presentation/pages/notification_settings_page.dart';
import 'package:tripbybid/features/profile/presentation/pages/payment_history_page.dart';
import 'package:tripbybid/features/profile/presentation/pages/profile_page.dart';
import 'package:tripbybid/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';

import '../../../../helpers/fixtures.dart';
import '../../../trips/trips_fakes.dart';
import '../../profile_fakes.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  late FakeProfileRepository profiles;

  setUp(() => profiles = FakeProfileRepository());

  group('ProfileView', () {
    late FakeTripsRepository trips;
    late int logouts;

    setUp(() {
      trips = FakeTripsRepository()
        ..myTripsResult = Ok([
          TripFixtures.request(
            status: 'confirmed',
            booking: TripFixtures.booking(price: 17999),
          ),
        ]);
      logouts = 0;
    });

    Future<void> pump(WidgetTester tester) async {
      final cubit = ProfileCubit(
        getProfile: GetProfileUseCase(profiles),
        getMyTrips: GetMyTripsUseCase(trips),
      );
      addTearDown(cubit.close);
      unawaited(cubit.load());
      await tester.pumpWidget(
        _app(
          BlocProvider.value(
            value: cubit,
            child: ProfileView(user: tUser, onLogout: () => logouts++),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the profile, stats and menu', (tester) async {
      await pump(tester);

      expect(find.text('Asha Rao'), findsOneWidget);
      expect(find.text('asha@example.com · Member since 2025'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('₹18K'), findsOneWidget);
      for (final label in [
        'ACCOUNT',
        'Personal details',
        'Payments & receipts',
        'PREFERENCES',
        'Notifications',
        'Help & support',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('logs out only after confirming', (tester) async {
      await pump(tester);

      await tester.scrollUntilVisible(find.text('Log out'), 200);
      await tester.ensureVisible(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(logouts, 0);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Log out'),
        ),
      );
      await tester.pumpAndSettle();
      expect(logouts, 1);
    });
  });

  group('NotificationSettingsView', () {
    Future<NotificationSettingsCubit> pump(WidgetTester tester) async {
      final cubit = NotificationSettingsCubit(
        getPreferences: GetNotificationPreferencesUseCase(profiles),
        updatePreferences: UpdateNotificationPreferencesUseCase(profiles),
      );
      addTearDown(cubit.close);
      unawaited(cubit.load());
      await tester.pumpWidget(
        _app(
          BlocProvider.value(
            value: cubit,
            child: const NotificationSettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return cubit;
    }

    bool toggleOf(WidgetTester tester, String label) => tester
        .widget<DesignToggle>(
          find.descendant(
            of: find.ancestor(
              of: find.text(label),
              matching: find.byType(MenuRow),
            ),
            matching: find.byType(DesignToggle),
          ),
        )
        .value;

    testWidgets('lists push and email switches', (tester) async {
      await pump(tester);

      expect(find.text('PUSH'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.byType(DesignToggle), findsNWidgets(7));
      expect(toggleOf(tester, 'Promotions'), isFalse);
      expect(toggleOf(tester, 'Booking alerts'), isTrue);
    });

    testWidgets('reverts a switch and shows a toast when saving fails', (
      tester,
    ) async {
      profiles.updatePreferencesResult = const Err(
        ServerFailure('Could not save preferences.'),
      );
      await pump(tester);

      await tester.tap(find.text('Booking alerts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(toggleOf(tester, 'Booking alerts'), isTrue);
      expect(find.text('Could not save preferences.'), findsOneWidget);
      expect(profiles.calls, contains('updatePreferences'));

      // Let the toast time out.
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('keeps a switch that saved', (tester) async {
      await pump(tester);

      await tester.ensureVisible(find.text('Promotions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Promotions'));
      await tester.pumpAndSettle();

      expect(toggleOf(tester, 'Promotions'), isTrue);
      expect(profiles.lastSavedPreferences?.emailPromotions, isTrue);
    });
  });

  group('PaymentHistoryView', () {
    late FakePaymentsRepository payments;

    setUp(() => payments = FakePaymentsRepository());

    Future<void> pump(WidgetTester tester) async {
      final cubit = PaymentHistoryCubit(
        getHistory: GetPaymentHistoryUseCase(payments),
      );
      addTearDown(cubit.close);
      unawaited(cubit.load());
      await tester.pumpWidget(
        _app(
          BlocProvider.value(value: cubit, child: const PaymentHistoryView()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows payments with status and receipt', (tester) async {
      payments.historyResult = Ok([
        ProfileFixtures.payment(),
        ProfileFixtures.payment(
          id: 'pay-2',
          status: 'refunded',
          receiptNumber: null,
        ),
      ]);
      await pump(tester);

      expect(find.text('Mumbai → Dubai'), findsNWidgets(2));
      expect(find.text('₹17,999'), findsNWidgets(2));
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Refunded'), findsOneWidget);
      expect(find.text('RECEIPT RCPT-0042'), findsOneWidget);
    });

    testWidgets('shows the empty state', (tester) async {
      await pump(tester);
      expect(find.text('No payments yet'), findsOneWidget);
    });
  });

  testWidgets('EditProfileView prefills the form and shows validation', (
    tester,
  ) async {
    final cubit = EditProfileCubit(
      getProfile: GetProfileUseCase(profiles),
      updateProfile: UpdateProfileUseCase(profiles),
    );
    addTearDown(cubit.close);
    unawaited(cubit.load());
    await tester.pumpWidget(
      _app(BlocProvider.value(value: cubit, child: const EditProfileView())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('asha@example.com'), findsOneWidget);
    expect(find.text('98100 43210'), findsOneWidget);
    expect(find.text('Window seat, always.'), findsOneWidget);

    await tester.enterText(find.text('98100 43210'), '12345');
    await tester.scrollUntilVisible(
      find.text('Save changes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a 10-digit Indian mobile number.'), findsOneWidget);
  });

  testWidgets('HelpPage opens an answer', (tester) async {
    await tester.pumpWidget(_app(const HelpPage()));

    expect(find.text('support@tripbybid.com'), findsOneWidget);
    expect(find.textContaining('Post one request'), findsNothing);
    await tester.tap(find.text('How does bidding work on TripByBid?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Post one request'), findsOneWidget);
  });
}
