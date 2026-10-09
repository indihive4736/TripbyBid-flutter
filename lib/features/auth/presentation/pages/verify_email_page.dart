import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/headings.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/verify_email_cubit.dart';
import '../widgets/auth_widgets.dart';

/// A7 — enter the 6-digit signup code emailed to [email].
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VerifyEmailCubit>()..start(email),
      child: const VerifyEmailView(),
    );
  }
}

/// The code screen, given a started [VerifyEmailCubit] and an [AuthBloc]
/// above it.
class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});

  KeyEventResult _onKey(BuildContext context, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final cubit = context.read<VerifyEmailCubit>();
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      cubit.backspace();
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) {
      cubit.digit(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<VerifyEmailCubit, VerifyEmailState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == VerifyStatus.success,
          listener: (context, state) {
            if (state.user case final user?) {
              context.read<AuthBloc>().add(AuthLoggedIn(user));
            }
          },
        ),
        BlocListener<VerifyEmailCubit, VerifyEmailState>(
          listenWhen: (previous, current) =>
              previous.resendStatus != current.resendStatus,
          listener: (context, state) {
            switch (state.resendStatus) {
              case ResendStatus.sent:
                showAppToast(
                  context,
                  'New code sent to ${state.email}',
                  icon: Symbols.mark_email_unread_rounded,
                );
              case ResendStatus.failed:
                showAppToast(
                  context,
                  state.resendError ?? 'Could not send a new code.',
                  icon: Symbols.error_rounded,
                );
              case ResendStatus.idle || ResendStatus.sending:
                break;
            }
          },
        ),
      ],
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) => _onKey(context, event),
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _CodeHeader()),
                _Keypad(
                  onDigit: context.read<VerifyEmailCubit>().digit,
                  onBackspace: context.read<VerifyEmailCubit>().backspace,
                  onPaste: () async {
                    final cubit = context.read<VerifyEmailCubit>();
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text case final text?) cubit.paste(text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeHeader extends StatelessWidget {
  const _CodeHeader();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VerifyEmailCubit>().state;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft, child: AuthBackButton()),
          const SizedBox(height: 26),
          const DisplayHeading(lead: 'Enter the ', accent: 'code.'),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Sent to ',
                style: AppTypography.body(16, color: AppColors.textSecondary),
              ),
              Text(
                state.email,
                style: AppTypography.body(16, weight: FontWeight.w700),
              ),
              Text(
                ' · ',
                style: AppTypography.body(16, color: AppColors.textSecondary),
              ),
              Semantics(
                button: true,
                label: 'Edit email',
                excludeSemantics: true,
                child: InkWell(
                  key: const Key('verify_edit'),
                  onTap: () => context.go(AppRoutes.signup),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Edit',
                      style: AppTypography.body(
                        16,
                        color: AppColors.accentDeep,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CodeBoxes(state: state),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _StatusLine(state: state),
              _ResendControl(state: state),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.state});

  final VerifyEmailState state;

  @override
  Widget build(BuildContext context) {
    final code = state.code;
    final failed = state.status == VerifyStatus.failure;
    final done = state.isComplete && !failed;
    return Semantics(
      label:
          'Verification code, ${code.length} of '
          '${VerifyEmailState.codeLength} digits entered',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < VerifyEmailState.codeLength; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _CodeBox(
                key: Key('verify_box_$i'),
                digit: i < code.length ? code[i] : '',
                border: failed
                    ? AppColors.danger
                    : done
                    ? AppColors.success
                    : i == code.length
                    ? AppColors.ink
                    : i < code.length
                    ? const Color(0x330D1B2A)
                    : const Color(0x1A0D1B2A),
                active: !done && !failed && i == code.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    super.key,
    required this.digit,
    required this.border,
    required this.active,
  });

  final String digit;
  final Color border;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border, width: 1.5),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x29FF5A1F), spreadRadius: 5)]
            : null,
      ),
      child: MediaQuery.withNoTextScaling(
        child: Text(digit, style: AppTypography.number(26)),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final VerifyEmailState state;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (state.status) {
      VerifyStatus.entering => (
        Symbols.mark_email_unread_rounded,
        state.digitsLeft == 1
            ? '1 digit to go'
            : '${state.digitsLeft} digits to go',
        AppColors.textSecondary,
      ),
      VerifyStatus.verifying => (
        Symbols.hourglass_top_rounded,
        'Verifying…',
        AppColors.textSecondary,
      ),
      VerifyStatus.success => (
        Symbols.check_circle_rounded,
        'Verified — logging you in',
        AppColors.success,
      ),
      VerifyStatus.failure => (
        Symbols.error_rounded,
        state.errorMessage ?? 'That code didn’t work.',
        AppColors.danger,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              key: const Key('verify_status'),
              style: AppTypography.body(
                14,
                color: color,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendControl extends StatelessWidget {
  const _ResendControl({required this.state});

  final VerifyEmailState state;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.body(14, color: AppColors.textTertiary);
    if (state.resendStatus == ResendStatus.sending) {
      return Text('Sending…', style: style);
    }
    if (state.resendIn > 0) {
      final minutes = state.resendIn ~/ 60;
      final seconds = (state.resendIn % 60).toString().padLeft(2, '0');
      return Text.rich(
        TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'Resend in '),
            TextSpan(
              text: '$minutes:$seconds',
              style: AppTypography.number(14, tracking: 0),
            ),
          ],
        ),
      );
    }
    return InkWell(
      key: const Key('verify_resend'),
      onTap: state.canResend
          ? () => context.read<VerifyEmailCubit>().resend()
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(
          'Resend code',
          style: AppTypography.body(
            14,
            color: AppColors.accentDeep,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// The on-screen number pad from the design.
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onPaste,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onPaste;

  static const _letters = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  @override
  Widget build(BuildContext context) {
    Widget digitKey(String d) => _Key(
      key: Key('key_$d'),
      semanticLabel: d,
      raised: true,
      onTap: () => onDigit(d),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            d,
            style: AppTypography.number(26, tracking: 0).copyWith(height: 1),
          ),
          if (_letters[d] case final letters?)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                letters,
                style: AppTypography.body(
                  9,
                  color: AppColors.textTertiary,
                ).copyWith(letterSpacing: 9 * 0.14),
              ),
            ),
        ],
      ),
    );

    final rows = [
      [digitKey('1'), digitKey('2'), digitKey('3')],
      [digitKey('4'), digitKey('5'), digitKey('6')],
      [digitKey('7'), digitKey('8'), digitKey('9')],
      [
        _Key(
          key: const Key('key_paste'),
          semanticLabel: 'Paste code',
          onTap: onPaste,
          child: const Icon(
            Symbols.content_paste_rounded,
            size: 22,
            color: AppColors.textTertiary,
          ),
        ),
        digitKey('0'),
        _Key(
          key: const Key('key_backspace'),
          semanticLabel: 'Delete',
          onTap: onBackspace,
          child: const Icon(
            Symbols.backspace_rounded,
            size: 24,
            color: AppColors.ink,
          ),
        ),
      ],
    ];

    return MediaQuery.withNoTextScaling(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          14,
          18,
          14 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.sunken,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: 8),
              Row(
                children: [
                  for (var c = 0; c < 3; c++) ...[
                    if (c > 0) const SizedBox(width: 8),
                    Expanded(child: rows[r][c]),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.raised = false,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: raised
              ? const [
                  BoxShadow(color: Color(0x1A0D1B2A), offset: Offset(0, 2)),
                ]
              : null,
        ),
        child: Material(
          color: raised ? AppColors.card : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: SizedBox(height: 56, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}
