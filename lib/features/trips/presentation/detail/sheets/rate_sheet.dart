import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../trip_detail_cubit.dart';
import 'sheet_common.dart';

/// Stars, quick tags and an optional comment for the agent.
class RateSheet extends StatefulWidget {
  const RateSheet({super.key, required this.agentName});

  final String agentName;

  static const labels = [
    'Tap a star to rate',
    'Poor',
    'Could be better',
    'Okay',
    'Great',
    'Excellent!',
  ];

  /// Quick tags; they go into the comment (the API takes text only).
  static const tags = ['On time', 'Great price', 'Helpful', 'Quick replies'];

  @override
  State<RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<RateSheet> {
  final _comment = TextEditingController();
  final _tags = <String>{};
  int _stars = 0;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      showAppToast(context, 'Tap a star first', icon: Symbols.star_rounded);
      return;
    }
    setState(() => _error = null);
    final comment = [
      if (_tags.isNotEmpty) RateSheet.tags.where(_tags.contains).join(', '),
      if (_comment.text.trim().isNotEmpty) _comment.text.trim(),
    ].join('. ');
    final outcome = await context.read<TripDetailCubit>().rate(
      rating: _stars,
      comment: comment,
    );
    if (!mounted) return;
    switch (outcome) {
      case ActionDone():
        Navigator.pop(context);
      case ActionFailed(:final message):
        setState(() => _error = message);
      case ActionAbandoned() || ActionIgnored() || RefundChanged():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<TripDetailCubit, bool>(
      (c) =>
          c.state is TripDetailLoaded &&
          (c.state as TripDetailLoaded).busy == DetailAction.rate,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: InitialsAvatar(name: widget.agentName, size: 56)),
        const SizedBox(height: 10),
        Text(
          'Rate ${widget.agentName}',
          textAlign: TextAlign.center,
          style: AppTypography.body(
            22,
            weight: FontWeight.w800,
          ).copyWith(letterSpacing: -0.03 * 22),
        ),
        const SizedBox(height: 2),
        Text(
          RateSheet.labels[_stars],
          textAlign: TextAlign.center,
          style: AppTypography.body(14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var n = 1; n <= 5; n++)
              _Star(
                value: n,
                on: n <= _stars,
                onTap: () => setState(() => _stars = n),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in RateSheet.tags)
              ChoicePill(
                label: tag,
                selected: _tags.contains(tag),
                onTap: () => setState(
                  () =>
                      _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Comment (optional)',
          controller: _comment,
          hint: 'What stood out?',
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (_error != null) SheetError(_error!),
        const SizedBox(height: 16),
        AppButton(
          label: 'Submit rating',
          style: AppButtonStyle.ink,
          height: 56,
          loading: busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _Star extends StatefulWidget {
  const _Star({required this.value, required this.on, required this.onTap});

  final int value;
  final bool on;
  final VoidCallback onTap;

  @override
  State<_Star> createState() => _StarState();
}

class _StarState extends State<_Star> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${widget.value} ${widget.value == 1 ? 'star' : 'stars'}',
      child: Semantics(
        button: true,
        selected: widget.on,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedScale(
              scale: _down ? 0.85 : 1,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Symbols.star_rounded,
                fill: 1,
                size: 44,
                color: widget.on
                    ? AppColors.starBright
                    : const Color(0x260D1B2A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
