import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/ink_panel.dart';
import '../widgets/help_faq.dart';
import '../widgets/profile_widgets.dart';

/// Traveler FAQs and how to reach support.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            const SubpageHeader(
              lead: 'Help & ',
              accent: 'support.',
              subtitle: 'Answers to common questions, or write to us.',
            ),
            const SizedBox(height: 20),
            const ContactCard(),
            for (final topic in faqTopics) ...[
              GroupLabel(topic.label),
              for (final entry in topic.entries) ...[
                FaqTile(entry: entry),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// The one support channel that exists today: email.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key});

  Future<void> _write(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: supportEmail);
    final opened = await launchUrl(uri).catchError((Object _) => false);
    if (!opened && context.mounted) {
      showAppToast(
        context,
        'No email app found. Write to $supportEmail',
        icon: Symbols.mail_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Email support at $supportEmail',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _write(context),
        child: InkPanel(
          padding: const EdgeInsets.all(18),
          borderRadius: const BorderRadius.all(Radius.circular(26)),
          glowSize: 220,
          glowOpacity: 0.35,
          shadow: false,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Symbols.mail_rounded,
                  size: 22,
                  color: AppColors.accentSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email support',
                      style: AppTypography.title(17, color: AppColors.onInk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supportEmail,
                      style: AppTypography.body(
                        13,
                        color: AppColors.onInkTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'We reply by email. Include your booking ID.',
                      style: AppTypography.body(
                        12,
                        color: AppColors.onInkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Symbols.arrow_forward_rounded,
                size: 20,
                color: AppColors.onInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A question that opens to show its answer.
class FaqTile extends StatefulWidget {
  const FaqTile({super.key, required this.entry});

  final FaqEntry entry;

  @override
  State<FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return AppCard(
      radius: 20,
      padding: EdgeInsets.zero,
      onTap: () => setState(() => _open = !_open),
      child: Semantics(
        expanded: _open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.entry.question,
                      style: AppTypography.body(15, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: duration,
                    turns: _open ? 0.5 : 0,
                    child: const Icon(
                      Symbols.expand_more_rounded,
                      size: 22,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, right: 8),
                        child: Text(
                          widget.entry.answer,
                          style: AppTypography.body(
                            14,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
