import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/inbox_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/domain/onboarding_repository.dart';
import '../../features/onboarding/presentation/pages/intro_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/help_page.dart';
import '../../features/profile/presentation/pages/notification_settings_page.dart';
import '../../features/profile/presentation/pages/payment_history_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/trips/domain/entities/trip_request.dart';
import '../../features/trips/presentation/pages/home_page.dart';
import '../../features/trips/presentation/pages/new_request_page.dart';
import '../../features/trips/presentation/pages/trip_detail_page.dart';
import '../../features/trips/presentation/pages/trips_page.dart';
import '../widgets/app_bottom_nav.dart';
import 'app_routes.dart';

/// Routes plus auth-driven redirects: signed-out users only see the
/// onboarding and auth screens; signed-in users skip them.
GoRouter createRouter(AuthBloc authBloc, OnboardingRepository onboarding) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _StreamListenable(authBloc.stream),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublic = AppRoutes.public.contains(location);
      return switch (authBloc.state) {
        AuthUnknown() => location == AppRoutes.splash ? null : AppRoutes.splash,
        Unauthenticated() when isPublic && location != AppRoutes.splash => null,
        // An expired session goes straight to login, which explains why.
        Unauthenticated(sessionExpired: true) => AppRoutes.login,
        Unauthenticated() =>
          onboarding.introSeen ? AppRoutes.welcome : AppRoutes.intro,
        Authenticated() => isPublic ? AppRoutes.home : null,
      };
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.intro, builder: (_, _) => const IntroPage()),
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupPage()),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, state) =>
            VerifyEmailPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, _) =>
                    _signedIn(context, (user) => HomePage(user: user)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.trips,
                builder: (_, _) => const TripsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.inbox,
                builder: (_, _) => const InboxPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, _) => _signedIn(
                  context,
                  (user) => ProfilePage(
                    user: user,
                    onLogout: () => context.read<AuthBloc>().add(
                      const AuthLogoutRequested(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newRequest,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: _signedIn(
            context,
            (user) => NewRequestPage(
              user: user,
              initialType: switch (state.uri.queryParameters['type']) {
                final String type => TripType.parse(type),
                null => null,
              },
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/trip/:id',
        builder: (_, state) => TripDetailPage(
          requestId: state.pathParameters['id']!,
          initialTab: state.uri.queryParameters['tab'],
        ),
      ),
      GoRoute(
        path: '/chat/:bookingId',
        builder: (context, state) => _signedIn(
          context,
          (user) => ChatPage(
            bookingId: state.pathParameters['bookingId']!,
            currentUserId: user.id,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, _) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (_, _) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.paymentHistory,
        builder: (_, _) => const PaymentHistoryPage(),
      ),
      GoRoute(path: AppRoutes.help, builder: (_, _) => const HelpPage()),
    ],
  );
}

/// Builds a page that needs the signed-in user. Redirects keep signed-out
/// users away; this covers the frame between logout and the redirect.
Widget _signedIn(BuildContext context, Widget Function(User user) builder) =>
    switch (context.read<AuthBloc>().state) {
      Authenticated(:final user) => builder(user),
      AuthUnknown() || Unauthenticated() => const SplashPage(),
    };

/// The four tabs with the floating nav bar and the centre "new request"
/// button.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});

  final StatefulNavigationShell shell;

  static const _items = [
    AppNavItem(icon: Symbols.home_rounded, label: 'Home'),
    AppNavItem(icon: Symbols.luggage_rounded, label: 'Trips'),
    AppNavItem(icon: Symbols.chat_rounded, label: 'Inbox'),
    AppNavItem(icon: Symbols.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: AppBottomNav(
        items: _items,
        currentIndex: shell.currentIndex,
        onSelect: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        onCreate: () => context.push(AppRoutes.newRequest),
      ),
    );
  }
}

/// Notifies [GoRouter] to re-run `redirect` whenever [stream] emits.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
