import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/usecases/login_usecase.dart';
import 'package:tripbybid/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tripbybid/features/auth/presentation/bloc/login_cubit.dart';
import 'package:tripbybid/features/auth/presentation/pages/login_page.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockLoginUseCase login;
  late AuthBloc authBloc;

  setUpAll(provideResultDummies);

  setUp(() {
    login = MockLoginUseCase();
    authBloc = AuthBloc(
      getCurrentUser: MockGetCurrentUserUseCase(),
      logout: MockLogoutUseCase(),
    );
  });

  tearDown(() => authBloc.close());

  Future<void> pumpLoginView(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: authBloc,
        child: BlocProvider(
          create: (_) => LoginCubit(login: login),
          child: const LoginView(),
        ),
      ),
    ),
  );

  Future<void> fillAndSubmit(WidgetTester tester, String password) async {
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'asha@example.com',
    );
    await tester.enterText(find.byKey(const Key('login_password')), password);
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('a successful login signs the user in', (tester) async {
    when(
      login(const LoginParams(email: 'asha@example.com', password: 'secret')),
    ).thenAnswer((_) async => const Ok(tUser));
    await pumpLoginView(tester);

    await fillAndSubmit(tester, 'secret');

    expect(authBloc.state, const Authenticated(tUser));
  });

  testWidgets('a failed login shows the error and stays signed out', (
    tester,
  ) async {
    when(login(any)).thenAnswer(
      (_) async => const Err(UnauthorizedFailure('Invalid credentials')),
    );
    await pumpLoginView(tester);

    await fillAndSubmit(tester, 'wrong');

    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(authBloc.state, const AuthUnknown());
  });
}
