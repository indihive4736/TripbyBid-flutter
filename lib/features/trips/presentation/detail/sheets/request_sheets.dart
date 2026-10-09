import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/trip_request.dart';
import '../../widgets/trip_style.dart';
import '../detail_labels.dart';
import '../trip_detail_cubit.dart';
import 'sheet_common.dart';

/// Edit the budget (before any bid) and the notes.
class EditRequestSheet extends StatefulWidget {
  const EditRequestSheet({
    super.key,
    required this.request,
    required this.budgetEditable,
  });

  final TripRequest request;

  /// Agents already bid: only the notes can change.
  final bool budgetEditable;

  @override
  State<EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<EditRequestSheet> {
  late final _budget = TextEditingController(
    text: widget.request.budget.round().toString(),
  );
  late final _notes = TextEditingController(
    text: widget.request.requirements ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _budget.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    double? budget;
    if (widget.budgetEditable) {
      budget = double.tryParse(_budget.text.trim());
      if (budget == null) {
        setState(() => _error = 'Enter your budget in rupees.');
        return;
      }
      if (budget == widget.request.budget) budget = null;
    }
    final notes = _notes.text.trim();
    final notesChanged = notes != (widget.request.requirements ?? '').trim();
    if (budget == null && !notesChanged) {
      Navigator.pop(context);
      return;
    }
    setState(() => _error = null);
    final outcome = await context.read<TripDetailCubit>().updateRequest(
      budget: budget,
      requirements: notesChanged ? notes : null,
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
          (c.state as TripDetailLoaded).busy == DetailAction.update,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          'Edit request',
          sub: widget.budgetEditable
              ? 'Agents see the changes straight away.'
              : 'Bids are in, so only the notes can change.',
        ),
        const SizedBox(height: 16),
        if (widget.budgetEditable) ...[
          AppTextField(
            label: 'Budget (₹, total)',
            controller: _budget,
            icon: Symbols.currency_rupee_rounded,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
        ],
        AppTextField(
          label: 'Notes for agents',
          controller: _notes,
          hint: 'Preferred times, seats, meals…',
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (_error != null) SheetError(_error!),
        const SizedBox(height: 16),
        AppButton(
          label: 'Save changes',
          height: 56,
          loading: busy,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// Raise a support ticket on a paid booking.
class SupportSheet extends StatefulWidget {
  const SupportSheet({super.key});

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  final _description = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _error = null);
    final outcome = await context.read<TripDetailCubit>().raiseSupportTicket(
      _description.text,
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
          (c.state as TripDetailLoaded).busy == DetailAction.support,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'Get help',
          sub: 'Describe the problem and the TripByBid team will follow up.',
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'What happened?',
          controller: _description,
          hint: 'At least 10 characters',
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (_error != null) SheetError(_error!),
        const SizedBox(height: 16),
        AppButton(
          label: 'Raise a ticket',
          style: AppButtonStyle.ink,
          leadingIcon: Symbols.support_agent_rounded,
          height: 56,
          loading: busy,
          onPressed: _send,
        ),
      ],
    );
  }
}

/// Everything the traveler asked for, as agents see it.
class RequestSummarySheet extends StatelessWidget {
  const RequestSummarySheet({super.key, required this.request});

  final TripRequest request;

  @override
  Widget build(BuildContext context) {
    final rows = <DetailRow>[
      (
        icon: request.type.icon,
        label: 'Trip',
        value: '${request.type.label} · ${request.title}',
      ),
      (
        icon: Symbols.payments_rounded,
        label: 'Budget',
        value: Fmt.inr(request.budget),
      ),
      ...requestDetailRows(request),
      (
        icon: Symbols.schedule_rounded,
        label: 'Posted',
        value: Fmt.dateTime(request.createdAt),
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          'Request summary',
          trailing: Semantics(
            button: true,
            label: 'Copy request ID',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () =>
                  Clipboard.setData(ClipboardData(text: request.shortId)),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  request.shortId,
                  style: AppTypography.eyebrow(
                    size: 12,
                    color: AppColors.textTertiary,
                    tracking: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(color: AppColors.hairline),
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(rows[i].icon, size: 19, color: AppColors.accentDeep),
                      const SizedBox(width: 12),
                      Text(
                        rows[i].label,
                        style: AppTypography.body(
                          14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rows[i].value,
                          textAlign: TextAlign.right,
                          style: AppTypography.body(
                            14,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Close',
          style: AppButtonStyle.outline,
          height: 52,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
