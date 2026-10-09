import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/';
}

/// Routes plus auth-driven redirects: nobody reaches a signed-in page without
/// an [Authenticated] state, and signed-in users skip splash and login.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _StreamListenable(authBloc.stream),
    redirect: (context, state) {
      final location = state.matchedLocation;
      return switch (authBloc.state) {
        AuthUnknown() => location == AppRoutes.splash ? null : AppRoutes.splash,
        Unauthenticated() =>
          location == AppRoutes.login ? null : AppRoutes.login,
        Authenticated() =>
          location == AppRoutes.splash || location == AppRoutes.login
              ? AppRoutes.home
              : null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => switch (context.read<AuthBloc>().state) {
          // Redirect normally keeps signed-out users away; this covers the
          // frame between logout and the redirect.
          Authenticated(:final user) => HomePage(
            user: user,
            onLogout: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
          AuthUnknown() || Unauthenticated() => const SplashPage(),
        },
      ),
    ],
  );
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
