import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../detail_labels.dart';
import '../trip_detail_cubit.dart';
import '../widgets/overview_tab.dart';
import 'sheet_common.dart';

/// "Pay securely": the total, its breakdown and the Cashfree checkout.
class PaySheet extends StatefulWidget {
  const PaySheet({super.key});

  @override
  State<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<PaySheet> {
  String? _error;

  Future<void> _pay() async {
    setState(() => _error = null);
    final outcome = await context.read<TripDetailCubit>().pay();
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
    final state = context.watch<TripDetailCubit>().state;
    if (state is! TripDetailLoaded) return const SizedBox.shrink();
    final detail = state.detail;
    final bid = detail.chosenBid;
    final summary = state.summary;
    final total = summary?.total ?? bid?.price ?? 0;
    final processing = state.busy == DetailAction.pay;
    final due = bid?.paymentDueAt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          'Pay securely',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Symbols.lock_rounded,
                size: 15,
                color: AppColors.successOnTint,
              ),
              const SizedBox(width: 4),
              Text(
                'Cashfree',
                style: AppTypography.body(
                  12,
                  weight: FontWeight.w700,
                  color: AppColors.successOnTint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.panelGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'To ${detail.agentName ?? 'your agent'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(13, color: AppColors.onInkTertiary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Fmt.inr(total),
                style: AppTypography.number(28, color: AppColors.onInk),
              ),
            ],
          ),
        ),
        if (summary != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                FareLine(label: 'Base fare', amount: summary.baseFare),
                FareLine(label: 'TripByBid fee', amount: summary.serviceCharge),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              const _MethodIcon(
                Symbols.account_balance_wallet_rounded,
                AppColors.successTint,
              ),
              const SizedBox(width: 4),
              const _MethodIcon(
                Symbols.credit_card_rounded,
                AppColors.hotelTint,
              ),
              const SizedBox(width: 4),
              const _MethodIcon(
                Symbols.account_balance_rounded,
                AppColors.yellowTint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choose UPI, card or netbanking in the secure Cashfree '
                  'checkout.',
                  style: AppTypography.body(
                    12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (due != null) ...[
          const SizedBox(height: 10),
          Text(
            'Fare held until ${Fmt.dateTime(due)}',
            textAlign: TextAlign.center,
            style: AppTypography.body(12, color: AppColors.textTertiary),
          ),
        ],
        if (_error != null) SheetError(_error!),
        const SizedBox(height: 14),
        AppButton(
          label: processing ? 'Processing…' : 'Pay ${Fmt.inr(total)}',
          leadingIcon: processing ? null : Symbols.lock_rounded,
          height: 56,
          onPressed: processing ? () {} : _pay,
        ),
      ],
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon(this.icon, this.tint);

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: AppColors.ink),
    );
  }
}
