import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/router/app_routes.dart';
import 'package:tripbybid/core/widgets/app_buttons.dart';
import 'package:tripbybid/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/sign_up_usecases.dart';
import 'package:tripbybid/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:tripbybid/features/auth/presentation/pages/signup_page.dart';

import '../../../../helpers/fakes.dart';
import 'auth_pages_test_support.dart';
import 'test_app.dart';

void main() {
  late FakeAuthRepository repository;
  late SignupCubit cubit;

  setUp(() {
    repository = FakeAuthRepository();
    cubit = SignupCubit(
      signUp: SignUpUseCase(repository),
      getCurrentUser: GetCurrentUserUseCase(repository),
    );
    addTearDown(cubit.close);
  });

  Future<void> pumpSignup(WidgetTester tester) => pumpRouted(
    tester,
    const SignupView(),
    wrap: provide(authBlocFor(repository), cubit),
  );

  bool submitEnabled(WidgetTester tester) =>
      tester
          .widget<AppButton>(find.byKey(const Key('signup_submit')))
          .onPressed !=
      null;

  String strengthLabel(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('signup_strength_label'))).data!;

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  testWidgets('the strength label follows the password', (tester) async {
    await pumpSignup(tester);
    expect(
      strengthLabel(tester),
      '8+ characters, a number, a capital and a symbol',
    );

    await type(tester, 'signup_password', 'travel');
    expect(strengthLabel(tester), 'Weak');

    await type(tester, 'signup_password', 'Travel12');
    expect(strengthLabel(tester), 'Good');

    await type(tester, 'signup_password', 'Travel#12');
    expect(strengthLabel(tester), 'Strong password');
  });

  testWidgets(
    'Create account enables only when every field is valid, then sends '
    'the code',
    (tester) async {
      await pumpSignup(tester);
      expect(find.text('Google'), findsNothing);
      expect(submitEnabled(tester), isFalse);

      await type(tester, 'signup_name', 'Asha Rao');
      await type(tester, 'signup_email', 'asha@example.com');
      await type(tester, 'signup_phone', '9810043210');
      await type(tester, 'signup_password', 'Travel#12');
      expect(submitEnabled(tester), isFalse, reason: 'terms not accepted');

      await tester.ensureVisible(find.byKey(const Key('signup_terms')));
      await tester.tap(find.byKey(const Key('signup_terms')));
      await tester.pump();
      expect(submitEnabled(tester), isTrue);

      await type(tester, 'signup_phone', '12345');
      expect(submitEnabled(tester), isFalse, reason: 'bad phone');
      await type(tester, 'signup_phone', '9810043210');
      expect(submitEnabled(tester), isTrue);

      await tester.ensureVisible(find.byKey(const Key('signup_submit')));
      await tester.tap(find.byKey(const Key('signup_submit')));
      await tester.pumpAndSettle();

      expect(repository.calls, ['signUp:asha@example.com:+919810043210']);
      expect(
        find.text('route:${AppRoutes.verifyEmailFor('asha@example.com')}'),
        findsOneWidget,
      );
    },
  );

  testWidgets('the phone field keeps digits only, up to ten', (tester) async {
    await pumpSignup(tester);
    await type(tester, 'signup_phone', '98-100 432109');
    expect(cubit.state.phone, '9810043210');
  });

  testWidgets('fits a small phone with large text', (tester) async {
    await pumpRouted(
      tester,
      const SignupView(),
      size: const Size(320, 568),
      wrap: (child) => provide(authBlocFor(repository), cubit)(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: child,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
