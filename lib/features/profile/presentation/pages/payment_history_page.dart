import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/headings.dart';
import '../../../../core/widgets/ink_panel.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../payments/domain/entities/checkout.dart';
import '../bloc/payment_history_cubit.dart';
import '../widgets/profile_widgets.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymentHistoryCubit>()..load(),
      child: const PaymentHistoryView(),
    );
  }
}

class PaymentHistoryView extends StatelessWidget {
  const PaymentHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentHistoryCubit>();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: BlocBuilder<PaymentHistoryCubit, PaymentHistoryState>(
            builder: (context, state) => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: SubpageHeader(
                      lead: 'Payments & ',
                      accent: 'receipts.',
                    ),
                  ),
                ),
                ...switch (state) {
                  PaymentHistoryLoading() => [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: LoadingView(),
                    ),
                  ],
                  PaymentHistoryError(:final message) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: StateMessage.error(
                        message: message,
                        onRetry: cubit.load,
                      ),
                    ),
                  ],
                  PaymentHistoryLoaded(:final payments) when payments.isEmpty =>
                    [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: StateMessage(
                          icon: Symbols.receipt_long_rounded,
                          title: 'No payments yet',
                          message:
                              'When you pay for a bid, the payment and its '
                              'receipt number show up here.',
                          actionLabel: 'Go to my trips',
                          onAction: () => context.go(AppRoutes.trips),
                        ),
                      ),
                    ],
                  PaymentHistoryLoaded(:final payments) => [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList.separated(
                        itemCount: payments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            PaymentTile(payment: payments[i]),
                      ),
                    ),
                  ],
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label and (background, foreground) for a payment status.
(String, Color, Color) paymentStatusStyle(String status) => switch (status) {
  'completed' => ('Paid', AppColors.successTint, AppColors.successOnTint),
  'pending' => ('Pending', AppColors.yellowTint, const Color(0xFF7A5300)),
  'failed' => ('Failed', const Color(0xFFFDE2E2), const Color(0xFFB42318)),
  'refunded' => ('Refunded', AppColors.hotelTint, const Color(0xFF3B4BA8)),
  'expired' => ('Expired', AppColors.muted, AppColors.textSecondary),
  'cancelled' => ('Cancelled', AppColors.muted, AppColors.textSecondary),
  _ => (
    status.isEmpty
        ? 'Unknown'
        : status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '),
    AppColors.muted,
    AppColors.textSecondary,
  ),
};

class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key, required this.payment});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final (label, bg, fg) = paymentStatusStyle(p.status);
    final date = (p.completedAt ?? p.createdAt).toLocal();
    final subtitle = [
      if (p.agentName != null && p.agentName!.isNotEmpty) p.agentName!,
      Fmt.date(date),
    ].join(' · ');
    return AppCard(
      radius: 26,
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: p.status == 'refunded'
                    ? Symbols.currency_exchange_rounded
                    : Symbols.receipt_long_rounded,
                tint: bg,
                color: fg,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tripTitle ?? 'Trip payment',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.body(
                        13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(Fmt.inr(p.amount), style: AppTypography.number(17)),
            ],
          ),
          const SizedBox(height: 12),
          const DashedLine(),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusPill(label: label, background: bg, foreground: fg),
              const SizedBox(width: 10),
              if (p.receiptNumber != null && p.receiptNumber!.isNotEmpty)
                Expanded(
                  child: Text(
                    'RECEIPT ${p.receiptNumber}',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.eyebrow(
                      size: 10.5,
                      color: AppColors.textTertiary,
                      tracking: 0.08,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
