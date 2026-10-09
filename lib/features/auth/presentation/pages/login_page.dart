import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/headings.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/login_cubit.dart';
import '../widgets/auth_widgets.dart';

/// A6 — email + password login.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: const LoginView(),
    );
  }
}

/// The login screen, given a [LoginCubit] and an [AuthBloc] above it.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  static const sessionExpiredMessage =
      'Your session expired. Please log in again.';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().submit(
      email: _email.text,
      password: _password.text,
    );
  }

  void _onState(BuildContext context, LoginState state) {
    switch (state) {
      case LoginState(status: LoginStatus.success, :final user?):
        context.read<AuthBloc>().add(AuthLoggedIn(user));
      case LoginState(
        status: LoginStatus.failure,
        emailNotVerified: true,
        :final email?,
      ):
        showAppToast(
          context,
          state.errorMessage ?? LoginCubit.codeResentMessage,
          icon: Symbols.mark_email_unread_rounded,
        );
        context.push(AppRoutes.verifyEmailFor(email));
      case LoginState(status: LoginStatus.failure, :final errorMessage?):
        showAppToast(context, errorMessage, icon: Symbols.error_rounded);
      case LoginState():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.select(
      (LoginCubit cubit) => cubit.state.status == LoginStatus.submitting,
    );
    final sessionExpired = context.select(
      (AuthBloc bloc) => switch (bloc.state) {
        Unauthenticated(:final sessionExpired) => sessionExpired,
        AuthUnknown() || Authenticated() => false,
      },
    );

    return BlocListener<LoginCubit, LoginState>(
      listener: _onState,
      child: Scaffold(
        body: AuthBackground(
          glow: const Alignment(0.8, -0.95),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: AuthBackButton(),
                          ),
                          const SizedBox(height: 26),
                          const DisplayHeading(
                            lead: 'Welcome ',
                            accent: 'back.',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Log in to see your bids and trips.',
                            style: AppTypography.body(
                              16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (sessionExpired) ...[
                            const SizedBox(height: 18),
                            const AuthNotice(
                              key: Key('login_session_expired'),
                              message: LoginView.sessionExpiredMessage,
                              icon: Symbols.lock_clock_rounded,
                            ),
                          ],
                          const SizedBox(height: 24),
                          AppTextField(
                            fieldKey: const Key('login_email'),
                            label: 'Email',
                            controller: _email,
                            enabled: !submitting,
                            hint: 'you@example.com',
                            icon: Symbols.mail_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            fieldKey: const Key('login_password'),
                            label: 'Password',
                            controller: _password,
                            enabled: !submitting,
                            hint: 'Your password',
                            icon: Symbols.lock_rounded,
                            obscureText: _obscured,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _submit(),
                            suffix: PasswordVisibilityToggle(
                              obscured: _obscured,
                              onToggle: () =>
                                  setState(() => _obscured = !_obscured),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            key: const Key('login_submit'),
                            label: 'Log in',
                            style: AppButtonStyle.ink,
                            icon: Symbols.arrow_forward_rounded,
                            loading: submitting,
                            onPressed: _submit,
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          AuthFooterLink(
                            key: const Key('login_to_signup'),
                            prompt: 'New to TripByBid?',
                            action: 'Sign up',
                            onTap: () =>
                                context.pushReplacement(AppRoutes.signup),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
