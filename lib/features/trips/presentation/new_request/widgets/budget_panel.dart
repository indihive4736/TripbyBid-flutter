import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/ink_panel.dart';
import '../new_request_cubit.dart';
import '../request_form_options.dart';

/// The navy "YOUR BUDGET" panel: big amount (tap to type one), slider on the
/// type's scale, min/max and a hint about how agents bid.
class BudgetPanel extends StatelessWidget {
  const BudgetPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewRequestCubit>();
    final (type, budget, range, tight) = context.select(
      (NewRequestCubit c) => (
        c.state.type,
        c.state.budget,
        c.state.budgetRange,
        c.state.budgetIsTight,
      ),
    );

    return InkPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      glow: const Alignment(0.72, -0.78),
      glowSize: 240,
      glowOpacity: 0.4,
      rings: false,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'YOUR BUDGET',
                style: AppTypography.eyebrow(color: AppColors.accentSoft),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  RequestFormOptions.budgetUnit(type),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(12, color: AppColors.onInkTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: 'Budget ${Fmt.inr(budget)}. Tap to type an exact amount.',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => _editExact(context, cubit, budget),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Fmt.inr(budget),
                        key: const Key('budget-amount'),
                        style: AppTypography.number(
                          52,
                          color: AppColors.onInk,
                          tracking: -0.05,
                        ).copyWith(height: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Symbols.edit_rounded,
                    size: 18,
                    color: AppColors.onInkFaint,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              padding: const EdgeInsets.symmetric(vertical: 10),
              activeTrackColor: const Color(0x29F3EDE3),
              inactiveTrackColor: const Color(0x29F3EDE3),
              thumbShape: const _RingThumb(),
              overlayColor: const Color(0x29FF5A1F),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              trackShape: const RoundedRectSliderTrackShape(),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: budget.clamp(range.min, range.max),
              min: range.min,
              max: range.max,
              onChanged: cubit.setBudget,
              semanticFormatterCallback: Fmt.inr,
            ),
          ),
          const SizedBox(height: 10),
          DefaultTextStyle(
            style: AppTypography.number(
              12,
              color: AppColors.onInkTertiary,
              weight: FontWeight.w500,
              tracking: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(Fmt.inr(range.min)), Text(Fmt.inr(range.max))],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x12FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Symbols.insights_rounded,
                  size: 18,
                  color: AppColors.accentSoft,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tight
                        ? 'Tight budget — fewer agents may bid'
                        : 'Agents usually bid 8–12% under this',
                    style: AppTypography.body(
                      13,
                      color: AppColors.onInkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _editExact(
    BuildContext context,
    NewRequestCubit cubit,
    double current,
  ) async {
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExactBudgetSheet(initial: current),
    );
    if (value != null) cubit.setExactBudget(value);
  }
}

class _ExactBudgetSheet extends StatefulWidget {
  const _ExactBudgetSheet({required this.initial});

  final double initial;

  @override
  State<_ExactBudgetSheet> createState() => _ExactBudgetSheetState();
}

class _ExactBudgetSheetState extends State<_ExactBudgetSheet> {
  late final _controller = TextEditingController(
    text: widget.initial.round().toString(),
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(double.parse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Set your budget', style: AppTypography.title(20)),
              const SizedBox(height: 4),
              Text(
                'The most you want to pay in total. Agents bid at or below it.',
                style: AppTypography.body(14, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('exact-budget'),
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                style: AppTypography.number(20, tracking: 0),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Symbols.currency_rupee_rounded, size: 20),
                ),
                validator: (text) {
                  final value = double.tryParse(text ?? '');
                  if (value == null || value <= 0) {
                    return 'Enter an amount above ₹0.';
                  }
                  if (value > RequestFormOptions.maxBudget) {
                    return 'Enter at most '
                        '${Fmt.inr(RequestFormOptions.maxBudget)}.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppButton(label: 'Set budget', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

/// The design's thumb: orange dot with a thick cream ring (26 px).
class _RingThumb extends SliderComponentShape {
  const _RingThumb();

  static const _radius = 13.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas
      ..drawCircle(
        center + const Offset(0, 2),
        _radius,
        Paint()
          ..color = const Color(0x660A1522)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(center, _radius, Paint()..color = AppColors.paper)
      ..drawCircle(center, _radius - 5, Paint()..color = AppColors.accent);
  }
}
