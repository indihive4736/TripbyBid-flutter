import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/segmented_tabs.dart';
import '../../../domain/entities/new_trip_request.dart';
import '../../../domain/entities/trip_request.dart';
import '../../widgets/trip_style.dart';
import '../new_request_cubit.dart';
import '../request_form_options.dart';
import 'budget_panel.dart';
import 'form_parts.dart';
import 'place_search_screen.dart';

/// Step 1 (design screen 04): trip type, route, dates, travellers, budget.
class RouteStep extends StatelessWidget {
  const RouteStep({super.key, required this.areaController});

  /// Hotels: the free-text area field.
  final TextEditingController areaController;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NewRequestCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        _TypeSelector(selected: state.type),
        const SizedBox(height: 14),
        _RouteCard(state: state, areaController: areaController),
        FieldError(
          state.errors[RequestField.from] ?? state.errors[RequestField.to],
        ),
        const SizedBox(height: 10),
        _DatesAndTravellers(state: state),
        const SizedBox(height: 14),
        const BudgetPanel(),
        FieldError(state.errors[RequestField.budget]),
      ],
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected});

  final TripType selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, type) in RequestFormOptions.types.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _TypeButton(
              type: type,
              selected: type == selected,
              onTap: () => context.read<NewRequestCubit>().selectType(type),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final TripType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onInk : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.ink : const Color(0x140D1B2A),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type.icon, size: 19, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  type.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    14,
                    color: fg,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// From/to card with the round navy swap button (city + area for hotels).
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.state, required this.areaController});

  final NewRequestState state;
  final TextEditingController areaController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewRequestCubit>();
    final type = state.type;
    final invalid =
        state.errors.containsKey(RequestField.from) ||
        state.errors.containsKey(RequestField.to);

    Future<void> pick({required bool from}) async {
      final place = await pickPlace(
        context,
        type: type,
        title: from
            ? RequestFormOptions.fromLabel(type)
            : RequestFormOptions.toLabel(type),
      );
      if (place == null) return;
      from ? cubit.setFrom(place) : cubit.setTo(place);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: invalid ? AppColors.danger : AppColors.hairline,
          width: invalid ? 1.5 : 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _PlaceRow(
                key: const Key('route-from'),
                label: RequestFormOptions.fromLabel(type),
                placeholder: RequestFormOptions.fromPlaceholder(type),
                place: state.from,
                marker: const _Marker.origin(),
                trailingSpace: !state.isHotel,
                onTap: () => pick(from: true),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 38, right: 16),
                color: const Color(0x140D1B2A),
              ),
              if (state.isHotel)
                _AreaRow(controller: areaController, onChanged: cubit.setArea)
              else
                _PlaceRow(
                  key: const Key('route-to'),
                  label: RequestFormOptions.toLabel(type),
                  placeholder: RequestFormOptions.toPlaceholder(type),
                  place: state.to,
                  marker: const _Marker.destination(),
                  trailingSpace: true,
                  onTap: () => pick(from: false),
                ),
            ],
          ),
          if (!state.isHotel)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Tooltip(
                  message: 'Swap origin and destination',
                  child: Material(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      key: const Key('route-swap'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: cubit.swap,
                      child: const SizedBox.square(
                        dimension: 44,
                        child: Icon(
                          Symbols.swap_vert_rounded,
                          size: 21,
                          color: AppColors.onInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker.origin() : origin = true;
  const _Marker.destination() : origin = false;

  final bool origin;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: origin
        ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: 2.5),
          )
        : BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(3),
          ),
  );
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    super.key,
    required this.label,
    required this.placeholder,
    required this.place,
    required this.marker,
    required this.trailingSpace,
    required this.onTap,
  });

  final String label;
  final String placeholder;
  final Place? place;
  final Widget marker;

  /// Keeps text clear of the swap button.
  final bool trailingSpace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = place;
    final title = p == null ? placeholder : placeTitle(p);
    final subtitle = p?.code == null ? null : p!.name;
    return Semantics(
      button: true,
      label: '$label: $title',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 66),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, trailingSpace ? 72 : 16, 12),
            child: Row(
              children: [
                marker,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FieldLabel(label),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          17,
                          weight: FontWeight.w700,
                          color: p == null
                              ? AppColors.textFaint
                              : AppColors.ink,
                        ),
                      ),
                      if (subtitle != null && subtitle != title)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            12,
                            color: AppColors.textTertiary,
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

/// "Mumbai (BOM)", "New Delhi (NDLS)", "Goa".
String placeTitle(Place p) {
  final code = p.code;
  if (code == null) return p.name;
  return '${p.city ?? p.name} ($code)';
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const _Marker.destination(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLabel(RequestFormOptions.toLabel(TripType.hotel)),
                TextField(
                  key: const Key('route-area'),
                  controller: controller,
                  onChanged: onChanged,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  style: AppTypography.body(17, weight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: RequestFormOptions.toPlaceholder(TripType.hotel),
                    hintStyle: AppTypography.body(
                      17,
                      weight: FontWeight.w700,
                      color: AppColors.textFaint,
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
}

class _DatesAndTravellers extends StatelessWidget {
  const _DatesAndTravellers({required this.state});

  final NewRequestState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewRequestCubit>();
    final type = state.type;
    final departError = state.errors[RequestField.depart];
    final returnError = state.errors[RequestField.ret];

    Future<void> pickDate({required bool isReturn}) async {
      final today = cubit.today;
      final depart = state.departDate;
      // Hotels check out at least a night later; flights may return same day.
      final first = isReturn && depart != null
          ? (state.isHotel ? depart.add(const Duration(days: 1)) : depart)
          : today;
      final current = isReturn ? state.returnDate : depart;
      final initial = current == null || current.isBefore(first)
          ? first
          : current;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: today.add(const Duration(days: 365)),
        helpText: switch ((type, isReturn)) {
          (TripType.hotel, false) => 'Check-in',
          (TripType.hotel, true) => 'Check-out',
          (_, true) => 'Return date',
          _ => 'Travel date',
        },
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.accent,
              onPrimary: AppColors.ink,
              surface: AppColors.sheet,
              onSurface: AppColors.ink,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.sheet,
              headerBackgroundColor: AppColors.ink,
              headerForegroundColor: AppColors.onInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          child: child!,
        ),
      );
      if (picked == null) return;
      isReturn ? cubit.setReturnDate(picked) : cubit.setDepartDate(picked);
    }

    final paxCard = _CounterCard(
      label: RequestFormOptions.paxLabel(type),
      value: state.adults,
      bounds: cubit.bounds(Counter.adults),
      onChanged: (v) => cubit.changeCount(Counter.adults, v - state.adults),
    );

    if (state.isHotel) {
      final nights = state.nights;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DateCard(
                  key: const Key('date-depart'),
                  label: 'Check-in',
                  date: state.departDate,
                  invalid: departError != null,
                  onTap: () => pickDate(isReturn: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateCard(
                  key: const Key('date-return'),
                  label: nights > 0
                      ? 'Check-out · $nights ${nights == 1 ? 'night' : 'nights'}'
                      : 'Check-out',
                  date: state.returnDate,
                  invalid: returnError != null,
                  onTap: () => pickDate(isReturn: true),
                ),
              ),
            ],
          ),
          FieldError(departError ?? returnError),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: paxCard),
              const SizedBox(width: 10),
              Expanded(
                child: _CounterCard(
                  label: 'Rooms',
                  value: state.rooms,
                  bounds: cubit.bounds(Counter.rooms),
                  onChanged: (v) =>
                      cubit.changeCount(Counter.rooms, v - state.rooms),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DateCard(
                  key: const Key('date-depart'),
                  label: state.isFlight && state.roundTrip ? 'Depart' : 'Date',
                  date: state.departDate,
                  invalid: departError != null,
                  onTap: () => pickDate(isReturn: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: paxCard),
            ],
          ),
        ),
        FieldError(departError),
        if (state.isFlight) ...[
          const SizedBox(height: 10),
          SegmentedTabs<bool>(
            options: const [
              SegmentOption(value: false, label: 'One-way'),
              SegmentOption(value: true, label: 'Round-trip'),
            ],
            selected: state.roundTrip,
            onChanged: cubit.setRoundTrip,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: state.roundTrip
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _DateCard(
                      key: const Key('date-return'),
                      label: 'Return',
                      date: state.returnDate,
                      invalid: returnError != null,
                      onTap: () => pickDate(isReturn: true),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          FieldError(returnError),
        ],
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    super.key,
    required this.label,
    required this.date,
    required this.invalid,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final bool invalid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = date;
    final text = d == null ? 'Pick a date' : Fmt.weekdayDayMonth(d);
    return FieldBox(
      onTap: onTap,
      invalid: invalid,
      semanticLabel: '$label: $text',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FieldLabel(label),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Symbols.calendar_month_rounded,
                  size: 18,
                  color: AppColors.accentDeep,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      16,
                      weight: FontWeight.w700,
                      color: d == null ? AppColors.textFaint : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.bounds,
    required this.onChanged,
  });

  final String label;
  final int value;
  final (int, int) bounds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return FieldBox(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: '$label: $value',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FieldLabel(label),
                  Text('$value', style: AppTypography.number(18, tracking: 0)),
                ],
              ),
            ),
          ),
          CountStepper(
            label: label.toLowerCase(),
            value: value,
            min: bounds.$1,
            max: bounds.$2,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
