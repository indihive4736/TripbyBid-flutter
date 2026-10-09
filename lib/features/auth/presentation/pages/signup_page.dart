import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../domain/entities/password_strength.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/signup_cubit.dart';
import '../widgets/auth_widgets.dart';

/// A8 — create a traveler account (step 1 of 2; the email code is step 2).
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignupCubit>(),
      child: const SignupView(),
    );
  }
}

/// The signup form, given a [SignupCubit] and an [AuthBloc] above it.
class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  bool _obscured = true;

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<SignupCubit>().submit();
  }

  void _onState(BuildContext context, SignupState state) {
    switch (state.status) {
      case SignupStatus.codeSent:
        context.go(AppRoutes.verifyEmailFor(state.email));
      case SignupStatus.signedIn:
        if (state.user case final user?) {
          context.read<AuthBloc>().add(AuthLoggedIn(user));
        }
      case SignupStatus.loginRequired:
        showAppToast(context, 'Account created — log in to continue.');
        context.go(AppRoutes.login);
      case SignupStatus.failure:
        if (state.errorMessage case final message?) {
          showAppToast(context, message, icon: Symbols.error_rounded);
        }
      case SignupStatus.editing || SignupStatus.submitting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SignupCubit>();
    return BlocConsumer<SignupCubit, SignupState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onState,
      builder: (context, state) {
        final submitting = state.status == SignupStatus.submitting;
        return Scaffold(
          body: AuthBackground(
            glow: const Alignment(-0.9, -1),
            glowOpacity: 0.2,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          AuthBackButton(),
                          Spacer(),
                          _StepDots(current: 0),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const DisplayHeading(
                        lead: 'Create your ',
                        accent: 'account.',
                        size: 38,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Free forever for travelers.',
                        style: AppTypography.body(
                          15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        fieldKey: const Key('signup_name'),
                        label: 'Full name',
                        hint: 'As on your ID',
                        icon: Symbols.person_rounded,
                        enabled: !submitting,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        onChanged: cubit.nameChanged,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        fieldKey: const Key('signup_email'),
                        label: 'Email',
                        hint: 'you@example.com',
                        icon: Symbols.mail_rounded,
                        enabled: !submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        onChanged: cubit.emailChanged,
                        suffix: state.emailLooksValid
                            ? const _ValidMark()
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _PhoneField(
                        enabled: !submitting,
                        valid: state.phoneLooksValid,
                        onChanged: cubit.phoneChanged,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        fieldKey: const Key('signup_password'),
                        label: 'Password',
                        hint: 'Create a password',
                        icon: Symbols.lock_rounded,
                        enabled: !submitting,
                        obscureText: _obscured,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: cubit.passwordChanged,
                        suffix: PasswordVisibilityToggle(
                          obscured: _obscured,
                          onToggle: () =>
                              setState(() => _obscured = !_obscured),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StrengthMeter(
                        strength: state.strength,
                        empty: state.password.isEmpty,
                      ),
                      const SizedBox(height: 12),
                      _TermsCheckbox(
                        checked: state.acceptedTerms,
                        onToggle: submitting ? null : cubit.termsToggled,
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        key: const Key('signup_submit'),
                        label: 'Create account',
                        icon: Symbols.arrow_forward_rounded,
                        loading: submitting,
                        onPressed: state.isValid ? _submit : null,
                      ),
                      const SizedBox(height: 18),
                      AuthFooterLink(
                        key: const Key('signup_to_login'),
                        prompt: 'Already have an account?',
                        action: 'Log in',
                        onTap: () => context.pushReplacement(AppRoutes.login),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${current + 1} of 2',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              width: 26,
              height: 6,
              decoration: BoxDecoration(
                color: i <= current
                    ? AppColors.accent
                    : const Color(0x240D1B2A),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValidMark extends StatelessWidget {
  const _ValidMark();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Symbols.check_circle_rounded,
      size: 19,
      fill: 1,
      color: AppColors.success,
      semanticLabel: 'Looks good',
    );
  }
}

/// Mobile number with a fixed +91 prefix; accepts the 10 local digits.
class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.enabled,
    required this.valid,
    required this.onChanged,
  });

  final bool enabled;
  final bool valid;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile number',
          style: AppTypography.body(13, weight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        TextFormField(
          key: const Key('signup_phone'),
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: onChanged,
          style: AppTypography.number(
            17,
            weight: FontWeight.w500,
            tracking: 0.02,
          ),
          decoration: InputDecoration(
            hintText: '98100 43210',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Container(
                padding: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.divider)),
                ),
                child: Text(
                  '+91',
                  style: AppTypography.body(16, weight: FontWeight.w700),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minHeight: 24),
            suffixIcon: valid ? const _ValidMark() : null,
          ),
        ),
      ],
    );
  }
}

/// Four bars plus a label that grade the password as it is typed.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength, required this.empty});

  final PasswordStrength strength;
  final bool empty;

  // Weak → strong. The two middle greens/ambers are the design's own.
  static const _colors = [
    AppColors.danger,
    AppColors.star,
    Color(0xFF4FA06F),
    AppColors.success,
  ];

  static const _hint = '8+ characters, a number, a capital and a symbol';

  @override
  Widget build(BuildContext context) {
    final score = strength.score;
    final color = _colors[score == 0 ? 0 : score - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < score ? color : const Color(0x1A0D1B2A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Text(
          empty ? _hint : strength.label,
          key: const Key('signup_strength_label'),
          style: AppTypography.body(
            12,
            weight: FontWeight.w600,
            color: empty ? AppColors.textTertiary : color,
          ),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.checked, required this.onToggle});

  final bool checked;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700);
    return Semantics(
      checked: checked,
      label: 'I agree to the Terms and Privacy Policy',
      excludeSemantics: true,
      child: InkWell(
        key: const Key('signup_terms'),
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: checked ? AppColors.ink : AppColors.card,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: checked ? AppColors.ink : const Color(0x400D1B2A),
                    width: 1.5,
                  ),
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: checked ? 1 : 0,
                  child: const Icon(
                    Symbols.check_rounded,
                    size: 16,
                    color: AppColors.onInk,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.body(
                      13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                    children: const [
                      TextSpan(text: 'I agree to the '),
                      TextSpan(text: 'Terms', style: bold),
                      TextSpan(text: ' and '),
                      TextSpan(text: 'Privacy Policy', style: bold),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
