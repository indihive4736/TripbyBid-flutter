import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/router/app_routes.dart';
import 'package:tripbybid/features/auth/domain/usecases/login_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/sign_up_usecases.dart';
import 'package:tripbybid/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tripbybid/features/auth/presentation/bloc/login_cubit.dart';
import 'package:tripbybid/features/auth/presentation/pages/login_page.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/fixtures.dart';
import 'auth_pages_test_support.dart';
import 'test_app.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthBloc authBloc;
  late LoginCubit cubit;

  setUp(() {
    repository = FakeAuthRepository();
    authBloc = authBlocFor(repository);
    cubit = LoginCubit(
      login: LoginUseCase(repository),
      resendCode: ResendCodeUseCase(repository),
    );
    addTearDown(cubit.close);
  });

  Future<void> pumpLogin(WidgetTester tester) =>
      pumpRouted(tester, const LoginView(), wrap: provide(authBloc, cubit));

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'asha@example.com',
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'Secret1!');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the email + password form only', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Log in to see your bids and trips.'), findsOneWidget);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);
    expect(find.text('Google'), findsNothing);
    expect(find.byKey(const Key('login_session_expired')), findsNothing);
  });

  testWidgets('a successful login signs the user in', (tester) async {
    repository.loginResult = const Ok(tUser);
    await pumpLogin(tester);

    await fillAndSubmit(tester);

    expect(authBloc.state, const Authenticated(tUser));
  });

  testWidgets('a wrong password shows the error', (tester) async {
    repository.loginResult = const Err(
      UnauthorizedFailure('Email or password is incorrect.'),
    );
    await pumpLogin(tester);

    await fillAndSubmit(tester);

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    await flushToasts(tester);
  });

  testWidgets('an unverified email resends a code and opens code entry', (
    tester,
  ) async {
    repository.loginResult = const Err(EmailNotVerifiedFailure());
    await pumpLogin(tester);

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(repository.calls, contains('resend:asha@example.com'));
    expect(
      find.text('route:${AppRoutes.verifyEmailFor('asha@example.com')}'),
      findsOneWidget,
    );
    await flushToasts(tester);
  });

  testWidgets('says why when the session expired', (tester) async {
    await tester.runAsync(() async {
      authBloc.add(const AuthLoggedIn(tUser));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      repository.endSession();
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    expect(authBloc.state, const Unauthenticated(sessionExpired: true));

    await pumpLogin(tester);

    expect(find.text(LoginView.sessionExpiredMessage), findsOneWidget);
  });

  testWidgets('Sign up switches to the signup screen', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('login_to_signup')));
    await tester.pumpAndSettle();

    expect(find.text('route:${AppRoutes.signup}'), findsOneWidget);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    await pumpRouted(
      tester,
      const LoginView(),
      size: const Size(320, 568),
      wrap: (child) => provide(authBloc, cubit)(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: child,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
