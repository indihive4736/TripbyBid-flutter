import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tripbybid/core/router/app_routes.dart';
import 'package:tripbybid/core/theme/app_theme.dart';

/// Pumps [screen] at `/` inside a router whose other public routes render
/// their path as text, so tests can assert where the screen navigated.
/// [wrap] provides blocs above the router.
Future<GoRouter> pumpRouted(
  WidgetTester tester,
  Widget screen, {
  Widget Function(Widget child)? wrap,
  Size size = const Size(390, 844),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget stub(String path) => Scaffold(body: Text('route:$path'));
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      for (final path in [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.home,
      ])
        GoRoute(path: path, builder: (_, _) => stub(path)),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, state) => stub(state.uri.toString()),
      ),
    ],
  );
  addTearDown(router.dispose);

  final app = MaterialApp.router(theme: AppTheme.light, routerConfig: router);
  await tester.pumpWidget(wrap == null ? app : wrap(app));
  return router;
}

/// Lets a toast's dismissal timer run out so no timers stay pending.
Future<void> flushToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
}
