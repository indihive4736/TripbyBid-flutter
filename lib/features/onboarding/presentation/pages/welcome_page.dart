import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/ink_panel.dart';
import '../widgets/ink_backdrop.dart';

/// A5 — choose between creating an account and logging in.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: InkBackdrop(
          ringCenter: Alignment.topRight,
          glows: const [
            BackdropGlow(
              center: Alignment(1.2, -0.92),
              diameter: 460,
              opacity: 0.5,
            ),
            BackdropGlow(
              center: Alignment(-1.05, 0.22),
              diameter: 420,
              opacity: 0.18,
            ),
          ],
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const BrandMark(size: 40),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'TripByBid',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.title(
                                  20,
                                  color: AppColors.onInk,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: _LovedByChip(),
                        ),
                        const SizedBox(height: 18),
                        Text.rich(
                          TextSpan(
                            style: AppTypography.display(
                              58,
                              color: AppColors.onInk,
                            ).copyWith(letterSpacing: -0.06 * 58, height: 0.9),
                            children: [
                              const TextSpan(text: 'Travel at '),
                              TextSpan(
                                text: 'your',
                                style: AppTypography.accent(
                                  59,
                                  color: AppColors.accentSoft,
                                ),
                              ),
                              const TextSpan(text: ' price.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Set a budget, let verified agents bid, book the '
                          'best deal.',
                          style: AppTypography.body(
                            16,
                            color: AppColors.onInkSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _StatStrip(),
                        const SizedBox(height: 22),
                        AppButton(
                          key: const Key('welcome_signup'),
                          label: 'Create free account',
                          icon: Symbols.arrow_forward_rounded,
                          onPressed: () => context.push(AppRoutes.signup),
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          key: const Key('welcome_login'),
                          label: 'I already have an account',
                          style: AppButtonStyle.outlineOnInk,
                          onPressed: () => context.push(AppRoutes.login),
                        ),
                        const SizedBox(height: 16),
                        Text.rich(
                          TextSpan(
                            style: AppTypography.body(
                              12,
                              color: AppColors.onInkFaint,
                            ),
                            children: const [
                              TextSpan(text: 'By continuing you agree to our '),
                              TextSpan(text: 'Terms', style: _link),
                              TextSpan(text: ' & '),
                              TextSpan(text: 'Privacy Policy', style: _link),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  static const _link = TextStyle(
    color: AppColors.onInk,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.onInk,
  );
}

class _LovedByChip extends StatelessWidget {
  const _LovedByChip();

  static const _faces = [
    Color(0xFFFFB199),
    Color(0xFF9ED9C9),
    Color(0xFFB9C4F5),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: 24 + 16.0 * (_faces.length - 1),
              height: 24,
              child: Stack(
                children: [
                  for (var i = 0; i < _faces.length; i++)
                    Positioned(
                      left: 16.0 * i,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _faces[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Loved by 50,000+ travelers',
              style: AppTypography.body(
                13,
                color: AppColors.onInk,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marketing figures from the design (not live data).
class _StatStrip extends StatelessWidget {
  const _StatStrip();

  @override
  Widget build(BuildContext context) {
    const rule = BorderSide(color: Color(0x1AFFFFFF));
    Widget stat(
      String value,
      String label, {
      Color? color,
      bool first = false,
      bool star = false,
    }) {
      final valueColor = color ?? AppColors.onInk;
      return Expanded(
        child: Container(
          padding: EdgeInsets.only(left: first ? 0 : 14),
          decoration: BoxDecoration(
            border: first ? null : const Border(left: rule),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: value,
                    children: [
                      if (star)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Symbols.star_rounded,
                            size: 20,
                            fill: 1,
                            color: valueColor,
                            semanticLabel: 'stars',
                          ),
                        ),
                    ],
                  ),
                  style: AppTypography.number(22, color: valueColor),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.body(11, color: AppColors.onInkTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: rule, bottom: rule),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            stat('5,000+', 'Verified agents', first: true),
            stat('~12%', 'Avg. saved', color: AppColors.mint),
            stat('4.8', 'App rating', star: true),
          ],
        ),
      ),
    );
  }
}
