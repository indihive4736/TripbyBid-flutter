import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/usecases/trip_actions.dart';
import '../trip_detail_cubit.dart';
import 'sheet_common.dart';

/// What the ticket sheet resolves to when the traveler reports a problem.
const ticketSheetReportProblem = 'report';

/// "Check your ticket": open it, confirm it, or report a problem.
class TicketSheet extends StatefulWidget {
  const TicketSheet({super.key, required this.onOpen});

  /// Opens the ticket's signed URL.
  final ValueChanged<String> onOpen;

  @override
  State<TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends State<TicketSheet> {
  String? _error;

  Future<void> _confirm() async {
    setState(() => _error = null);
    final outcome = await context.read<TripDetailCubit>().verifyTicket();
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
    final ticket = state.detail.booking?.ticket;
    final url = ticket?.url;
    final busy = state.busy == DetailAction.verify;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'Check your ticket',
          sub:
              'Make sure names, dates and times are right before you '
              'confirm.',
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(14),
          onTap: url == null ? null : () => widget.onOpen(url),
          child: Row(
            children: [
              const IconTile(
                icon: Symbols.confirmation_number_rounded,
                tint: AppColors.flightTint,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket?.fileName ?? 'E-ticket',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(15, weight: FontWeight.w700),
                    ),
                    Text(
                      ticket == null
                          ? 'Not uploaded yet'
                          : url == null
                          ? 'Open it on the web dashboard'
                          : 'Uploaded ${Fmt.dateTime(ticket.uploadedAt)}',
                      style: AppTypography.body(
                        12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (url != null)
                const Icon(
                  Symbols.open_in_new_rounded,
                  size: 20,
                  color: AppColors.ink,
                  semanticLabel: 'Open ticket',
                ),
            ],
          ),
        ),
        if (url != null) ...[
          const SizedBox(height: 10),
          AppButton(
            label: 'Open ticket',
            style: AppButtonStyle.outline,
            leadingIcon: Symbols.open_in_new_rounded,
            height: 52,
            onPressed: () => widget.onOpen(url),
          ),
        ],
        if (_error != null) SheetError(_error!),
        const SizedBox(height: 14),
        AppButton(
          label: 'Looks good — confirm',
          leadingIcon: Symbols.check_rounded,
          height: 56,
          loading: busy,
          onPressed: _confirm,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Something\'s wrong',
          style: AppButtonStyle.outline,
          leadingIcon: Symbols.report_rounded,
          height: 52,
          onPressed: busy
              ? null
              : () => Navigator.pop(context, ticketSheetReportProblem),
        ),
      ],
    );
  }
}

/// Pick what is wrong with the ticket and ask the agent to fix it.
class CorrectionSheet extends StatefulWidget {
  const CorrectionSheet({super.key});

  @override
  State<CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends State<CorrectionSheet> {
  final _details = TextEditingController();
  final _reasons = <String>{};
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _error = null);
    final outcome = await context.read<TripDetailCubit>().requestCorrection(
      reasons: RequestCorrectionUseCase.reasons
          .where(_reasons.contains)
          .toList(),
      details: _details.text,
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
          (c.state as TripDetailLoaded).busy == DetailAction.correction,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'What\'s wrong?',
          sub: 'Your agent gets this and uploads a corrected ticket.',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reason in RequestCorrectionUseCase.reasons)
              ChoicePill(
                label: reason,
                selected: _reasons.contains(reason),
                onTap: () => setState(
                  () => _reasons.contains(reason)
                      ? _reasons.remove(reason)
                      : _reasons.add(reason),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Details (optional)',
          controller: _details,
          hint: 'e.g. the correct spelling of the name',
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (_error != null) SheetError(_error!),
        const SizedBox(height: 16),
        AppButton(
          label: 'Send to agent',
          height: 56,
          loading: busy,
          onPressed: _send,
        ),
      ],
    );
  }
}
