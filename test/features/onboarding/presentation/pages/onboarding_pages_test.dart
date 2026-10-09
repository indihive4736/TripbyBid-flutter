import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/router/app_routes.dart';
import 'package:tripbybid/features/onboarding/domain/mark_intro_seen_usecase.dart';
import 'package:tripbybid/features/onboarding/presentation/bloc/intro_cubit.dart';
import 'package:tripbybid/features/onboarding/presentation/pages/intro_page.dart';
import 'package:tripbybid/features/onboarding/presentation/pages/splash_page.dart';
import 'package:tripbybid/features/onboarding/presentation/pages/welcome_page.dart';

import '../../../auth/presentation/pages/test_app.dart';
import '../../onboarding_fakes.dart';

void main() {
  group('IntroView', () {
    late FakeOnboardingRepository repository;

    setUp(() => repository = FakeOnboardingRepository());

    Future<void> pumpIntro(WidgetTester tester) => pumpRouted(
      tester,
      BlocProvider(
        create: (_) =>
            IntroCubit(markIntroSeen: MarkIntroSeenUseCase(repository)),
        child: const IntroView(),
      ),
    );

    testWidgets('Skip marks the intro seen and opens welcome', (tester) async {
      await pumpIntro(tester);
      expect(find.text('STEP 01'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.introSeen, isTrue);
      expect(find.text('route:${AppRoutes.welcome}'), findsOneWidget);
    });

    testWidgets('the arrow walks the slides, then Get started finishes', (
      tester,
    ) async {
      await pumpIntro(tester);

      await tester.tap(find.byKey(const Key('intro_next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('STEP 02'), findsOneWidget);

      await tester.tap(find.byKey(const Key('intro_next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('STEP 03'), findsOneWidget);
      expect(find.byKey(const Key('intro_next')), findsNothing);

      await tester.tap(find.byKey(const Key('intro_get_started')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.introSeen, isTrue);
      expect(find.text('route:${AppRoutes.welcome}'), findsOneWidget);
    });
  });

  testWidgets('SplashPage shows the brand and never navigates', (tester) async {
    await pumpRouted(tester, const SplashPage());
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('TripByBid'), findsOneWidget);
    expect(find.text('MADE IN INDIA · V1.0'), findsOneWidget);
  });

  testWidgets('SplashPage holds still with reduced motion', (tester) async {
    await pumpRouted(
      tester,
      const SplashPage(),
      wrap: (child) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: child,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TripByBid'), findsOneWidget);
  });

  group('WelcomePage', () {
    testWidgets('Create free account opens signup', (tester) async {
      await pumpRouted(tester, const WelcomePage());
      await tester.tap(find.byKey(const Key('welcome_signup')));
      await tester.pumpAndSettle();
      expect(find.text('route:${AppRoutes.signup}'), findsOneWidget);
    });

    testWidgets('I already have an account opens login', (tester) async {
      await pumpRouted(tester, const WelcomePage());
      await tester.tap(find.byKey(const Key('welcome_login')));
      await tester.pumpAndSettle();
      expect(find.text('route:${AppRoutes.login}'), findsOneWidget);
    });

    testWidgets('fits a small phone with large text', (tester) async {
      await pumpRouted(
        tester,
        const WelcomePage(),
        size: const Size(320, 568),
        wrap: (child) => MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: child,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
