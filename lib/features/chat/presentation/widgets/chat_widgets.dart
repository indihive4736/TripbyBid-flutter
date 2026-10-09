import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/chat_usecases.dart';
import 'chat_style.dart';

/// Cream header: back, agent avatar, agent name and the trip title.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.agentName,
    required this.subtitle,
    required this.onBack,
  });

  final String agentName;
  final String? subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            12,
            MediaQuery.paddingOf(context).top + 6,
            16,
            14,
          ),
          decoration: BoxDecoration(
            color: AppColors.paper.withValues(alpha: 0.9),
            border: const Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Row(
            children: [
              Tooltip(
                message: 'Back',
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: onBack,
                    child: const SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        Symbols.arrow_back_rounded,
                        size: 22,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InitialsAvatar(name: agentName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(16, weight: FontWeight.w700),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          12,
                          color: AppColors.textTertiary,
                          weight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "✈ Mumbai → Dubai · #9A21C0D3" — the booking this thread is about.
class TripContextChip extends StatelessWidget {
  const TripContextChip({super.key, required this.conversation, this.onTap});

  final Conversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return Semantics(
      button: onTap != null,
      label: 'Booking ${c.title}, ${c.shortRef}',
      excludeSemantics: true,
      child: AppCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            Icon(c.tripIcon, size: 18, color: AppColors.accentDeep),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(13, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '· ${c.shortRef}',
              style: AppTypography.body(13, color: AppColors.textTertiary),
            ),
            const Spacer(),
            if (onTap != null)
              const Icon(
                Symbols.chevron_right_rounded,
                size: 18,
                color: AppColors.textFaint,
              ),
          ],
        ),
      ),
    );
  }
}

/// Mono day label between messages: TODAY, YESTERDAY, 22 SEP.
class DaySeparator extends StatelessWidget {
  const DaySeparator({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow(
            color: AppColors.textTertiary,
            tracking: 0.1,
          ),
        ),
      ),
    );
  }
}

/// Automatic status message, centred and muted.
class SystemNote extends StatelessWidget {
  const SystemNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.body(
            12,
            color: AppColors.textTertiary,
            weight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

enum BubbleDelivery { sent, sending, failed }

/// A chat bubble. Mine: navy, right-aligned; theirs: cream card, left.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.mine,
    required this.timeLabel,
    this.delivery = BubbleDelivery.sent,
    this.onRetry,
    this.onDiscard,
  });

  final String text;
  final bool mine;
  final String timeLabel;
  final BubbleDelivery delivery;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final failed = delivery == BubbleDelivery.failed;
    final radius = mine
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          );
    final bubble = LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.78),
        child: Opacity(
          opacity: delivery == BubbleDelivery.sending ? 0.6 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: mine ? AppColors.ink : AppColors.card,
              borderRadius: radius,
              border: failed
                  ? Border.all(color: AppColors.danger, width: 1.5)
                  : null,
              boxShadow: mine
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x660D1B2A),
                        offset: Offset(0, 6),
                        blurRadius: 16,
                        spreadRadius: -12,
                      ),
                    ],
            ),
            child: Text(
              text,
              style: AppTypography.body(
                15,
                color: mine ? AppColors.onInk : AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );

    final meta = failed
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Symbols.error_rounded,
                size: 13,
                color: AppColors.danger,
              ),
              const SizedBox(width: 4),
              Text(
                'Not sent · Tap to retry',
                style: AppTypography.eyebrow(
                  size: 10,
                  color: AppColors.danger,
                  tracking: 0,
                ),
              ),
            ],
          )
        : Text(
            delivery == BubbleDelivery.sending ? 'Sending…' : timeLabel,
            style: AppTypography.eyebrow(
              size: 10,
              color: AppColors.textTertiary,
              tracking: 0,
            ),
          );

    final column = Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        bubble,
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: meta,
        ),
      ],
    );

    if (!failed) return column;
    return Semantics(
      button: true,
      hint: 'Message not sent. Double tap to retry, long press to delete.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRetry,
        onLongPress: onDiscard,
        child: column,
      ),
    );
  }
}

/// Suggested first messages, inserted into the draft.
class QuickReplies extends StatelessWidget {
  const QuickReplies({super.key, required this.onPick});

  static const replies = [
    'Can you hold this fare?',
    'Any better option?',
    'Is cancellation free?',
  ];

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Center(
          child: Material(
            color: AppColors.card,
            shape: const StadiumBorder(
              side: BorderSide(color: AppColors.divider),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onPick(replies[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Text(
                  replies[i],
                  style: AppTypography.body(13, weight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cream bar with the message field and the orange send button.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSend,
    this.top,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  /// Shown above the field (quick replies).
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0x140D1B2A)),
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper.withValues(alpha: 0.94),
            border: const Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (top != null) ...[const SizedBox(height: 8), top!],
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              SendMessageUseCase.maxLength,
                            ),
                          ],
                          style: AppTypography.body(15),
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: AppTypography.body(
                              15,
                              color: AppColors.textFaint,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: border,
                            enabledBorder: border,
                            focusedBorder: border.copyWith(
                              borderSide: const BorderSide(
                                color: AppColors.ink,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, value, _) => _SendButton(
                          onPressed: value.text.trim().isEmpty ? null : onSend,
                        ),
                      ),
                    ],
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

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: 'Send',
      child: Semantics(
        button: true,
        enabled: enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onPressed,
                child: const Icon(
                  Symbols.send_rounded,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
