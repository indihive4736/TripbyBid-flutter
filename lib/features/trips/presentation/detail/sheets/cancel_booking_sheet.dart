import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/error/result.dart';
import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/entities/trip_detail.dart';
import '../trip_detail_cubit.dart';
import 'sheet_common.dart';

/// "Cancel this booking?" with reasons and the live refund quote.
class CancelBookingSheet extends StatefulWidget {
  const CancelBookingSheet({super.key});

  static const reasons = [
    'Plans changed',
    'Found cheaper',
    'Wrong details',
    'Other',
  ];

  @override
  State<CancelBookingSheet> createState() => _CancelBookingSheetState();
}

class _CancelBookingSheetState extends State<CancelBookingSheet> {
  CancellationQuote? _quote;
  String? _quoteError;
  String? _error;
  String? _reason;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _quote = null;
      _quoteError = null;
    });
    final result = await context.read<TripDetailCubit>().cancellationQuote();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(:final value):
          _quote = value;
        case Err(:final failure):
          _quoteError = failure.message;
      }
    });
  }

  Future<void> _cancel() async {
    final quote = _quote;
    if (quote == null) return;
    if (_reason == null) {
      showAppToast(context, 'Pick a reason first', icon: Symbols.info_rounded);
      return;
    }
    setState(() => _error = null);
    final outcome = await context.read<TripDetailCubit>().cancelBooking(
      quote: quote,
      reason: _reason,
    );
    if (!mounted) return;
    switch (outcome) {
      case ActionDone():
        Navigator.pop(context);
      case RefundChanged(:final quote):
        setState(() => _quote = quote);
      case ActionFailed(:final message):
        setState(() => _error = message);
      case ActionAbandoned() || ActionIgnored():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<TripDetailCubit, bool>(
      (c) =>
          c.state is TripDetailLoaded &&
          (c.state as TripDetailLoaded).busy == DetailAction.cancelBooking,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'Cancel this booking?',
          sub: 'Tell us why — it helps agents improve.',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reason in CancelBookingSheet.reasons)
              ChoicePill(
                label: reason,
                selected: _reason == reason,
                onTap: () => setState(() => _reason = reason),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _RefundPanel(quote: _quote, error: _quoteError, onRetry: _fetch),
        if (_error != null) SheetError(_error!),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Keep booking',
                style: AppButtonStyle.outline,
                height: 54,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Yes, cancel',
                style: AppButtonStyle.danger,
                height: 54,
                loading: busy,
                onPressed: _quote == null ? null : _cancel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RefundPanel extends StatelessWidget {
  const _RefundPanel({
    required this.quote,
    required this.error,
    required this.onRetry,
  });

  final CancellationQuote? quote;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    if (q == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: error == null
            ? Row(
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Working out your refund…',
                    style: AppTypography.body(14, weight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      error!,
                      style: AppTypography.body(13, color: AppColors.danger),
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
      );
    }
    final full = q.refund >= q.fare;
    final fg = full ? AppColors.successOnTint : AppColors.accentOnTint;
    TextStyle line([Color? color]) =>
        AppTypography.body(12, color: color ?? AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: full ? AppColors.successTint : AppColors.accentTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.currency_exchange_rounded, size: 22, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You get back ${Fmt.inr(q.refund)}',
                  style: AppTypography.body(14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _Row('Fare', Fmt.inr(q.fare), line()),
                _Row(
                  'Cancellation charge',
                  q.charge == 0 ? 'None' : '− ${Fmt.inr(q.charge)}',
                  line(),
                ),
                _Row(
                  q.platformFeeKept
                      ? 'TripByBid fee (kept)'
                      : 'TripByBid fee (refunded)',
                  Fmt.inr(q.platformFee),
                  line(),
                ),
                if (q.policyTitle != null || q.appliesUntil != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (q.policyTitle != null) q.policyTitle!,
                      if (q.appliesUntil != null)
                        'This amount applies until '
                            '${Fmt.dateTime(q.appliesUntil!)}',
                    ].join(' · '),
                    style: line(AppColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, this.style);

  final String label;
  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: AppTypography.number(12, tracking: 0, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
