import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/router/app_routes.dart';
import 'package:tripbybid/features/auth/domain/usecases/sign_up_usecases.dart';
import 'package:tripbybid/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tripbybid/features/auth/presentation/bloc/verify_email_cubit.dart';
import 'package:tripbybid/features/auth/presentation/pages/verify_email_page.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/fixtures.dart';
import 'auth_pages_test_support.dart';
import 'test_app.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthBloc authBloc;
  late VerifyEmailCubit cubit;

  setUp(() {
    repository = FakeAuthRepository();
    authBloc = authBlocFor(repository);
  });

  Future<void> pumpVerify(WidgetTester tester) async {
    cubit = VerifyEmailCubit(
      verifyEmail: VerifyEmailUseCase(repository),
      resendCode: ResendCodeUseCase(repository),
      resendCooldown: 3,
    )..start('asha@example.com');
    await pumpRouted(
      tester,
      const VerifyEmailView(),
      wrap: provide(authBloc, cubit),
    );
  }

  /// Closes the cubit so its countdown timer is gone before the test ends.
  Future<void> finish(WidgetTester tester) async {
    await cubit.close();
    await tester.pump();
  }

  String box(WidgetTester tester, int i) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(Key('verify_box_$i')),
          matching: find.byType(Text),
        ),
      )
      .data!;

  String status(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('verify_status'))).data!;

  testWidgets('keypad taps fill the boxes and count down the digits', (
    tester,
  ) async {
    await pumpVerify(tester);
    expect(find.text('asha@example.com'), findsOneWidget);
    expect(status(tester), '6 digits to go');

    await tester.tap(find.byKey(const Key('key_4')));
    await tester.tap(find.byKey(const Key('key_8')));
    await tester.pump();
    expect(box(tester, 0), '4');
    expect(box(tester, 1), '8');
    expect(box(tester, 2), '');
    expect(status(tester), '4 digits to go');

    await tester.tap(find.byKey(const Key('key_backspace')));
    await tester.pump();
    expect(box(tester, 1), '');
    expect(status(tester), '5 digits to go');

    await finish(tester);
  });

  testWidgets('the sixth digit verifies and signs the user in', (tester) async {
    repository.verifyResult = const Ok(tUser);
    await pumpVerify(tester);

    for (final d in '482190'.split('')) {
      await tester.tap(find.byKey(Key('key_$d')));
    }
    await tester.pump();
    await tester.pump();

    expect(repository.calls, contains('verify:asha@example.com:482190'));
    expect(status(tester), 'Verified — logging you in');
    expect(authBloc.state, const Authenticated(tUser));

    await finish(tester);
  });

  testWidgets('a wrong code shows the error', (tester) async {
    repository.verifyResult = const Err(
      ServerFailure('Invalid or expired code.'),
    );
    await pumpVerify(tester);

    for (final d in '111111'.split('')) {
      await tester.tap(find.byKey(Key('key_$d')));
    }
    await tester.pump();
    await tester.pump();

    expect(status(tester), 'Invalid or expired code.');
    await finish(tester);
  });

  testWidgets('hardware digits and paste work too', (tester) async {
    repository.verifyResult = const Err(ServerFailure('nope'));
    await pumpVerify(tester);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();
    expect(box(tester, 0), '7');

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, Object?>{'text': '123 456'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.byKey(const Key('key_paste')));
    await tester.pump();
    await tester.pump();

    expect(repository.calls, contains('verify:asha@example.com:123456'));
    await finish(tester);
  });

  testWidgets('the countdown turns into a working Resend code link', (
    tester,
  ) async {
    await pumpVerify(tester);
    expect(find.textContaining('Resend in'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const Key('verify_resend')), findsOneWidget);

    await tester.tap(find.byKey(const Key('verify_resend')));
    await tester.pump();
    await tester.pump();

    expect(repository.calls, contains('resend:asha@example.com'));
    expect(find.text('New code sent to asha@example.com'), findsOneWidget);
    expect(find.textContaining('Resend in'), findsOneWidget);

    await flushToasts(tester);
    await finish(tester);
  });

  testWidgets('Edit goes back to signup', (tester) async {
    await pumpVerify(tester);

    await tester.tap(find.byKey(const Key('verify_edit')));
    await tester.pumpAndSettle();

    expect(find.text('route:${AppRoutes.signup}'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    cubit = VerifyEmailCubit(
      verifyEmail: VerifyEmailUseCase(repository),
      resendCode: ResendCodeUseCase(repository),
    )..start('a.very.long.address@example.com');
    await pumpRouted(
      tester,
      const VerifyEmailView(),
      size: const Size(320, 568),
      wrap: (child) => provide(authBloc, cubit)(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: child,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
