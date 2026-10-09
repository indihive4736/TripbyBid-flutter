import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/headings.dart';

/// Back button above a display heading — the header of profile sub-pages.
class SubpageHeader extends StatelessWidget {
  const SubpageHeader({
    super.key,
    required this.lead,
    required this.accent,
    this.subtitle,
  });

  final String lead;
  final String accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconButton(
          icon: Symbols.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
        const SizedBox(height: 18),
        Semantics(
          header: true,
          child: DisplayHeading(lead: lead, accent: accent, size: 34),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: AppTypography.body(
              14,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// Mono group label: "ACCOUNT".
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.eyebrow(color: AppColors.textTertiary),
      ),
    );
  }
}

/// A labelled card of rows separated by hairlines.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupLabel(label),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.hairline),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Menu row: icon tile, label, optional meta, then a chevron or [trailing].
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.label,
    this.meta,
    this.onTap,
    this.trailing,
    this.semanticsToggled,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String? meta;
  final VoidCallback? onTap;

  /// Replaces the chevron (e.g. a toggle).
  final Widget? trailing;

  /// For toggle rows: the switch state announced to screen readers.
  final bool? semanticsToggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: semanticsToggled == null,
      toggled: semanticsToggled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                IconTile(icon: icon, tint: tint, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body(15, weight: FontWeight.w600),
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    meta!,
                    style: AppTypography.body(
                      13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                trailing ??
                    const Icon(
                      Symbols.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textFaint,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's switch: 48×28 pill, green when on, white knob.
class DesignToggle extends StatelessWidget {
  const DesignToggle({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return AnimatedContainer(
      duration: duration,
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: value ? AppColors.success : const Color(0x2E0D1B2A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
