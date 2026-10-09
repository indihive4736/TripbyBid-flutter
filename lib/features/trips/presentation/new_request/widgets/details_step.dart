import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../widgets/trip_style.dart';
import '../new_request_cubit.dart';
import '../request_form_options.dart';
import 'form_parts.dart';
import 'route_step.dart' show placeTitle;

/// Step 2: class and preferences, who is travelling, notes, contact and a
/// review of the whole request.
class DetailsStep extends StatelessWidget {
  const DetailsStep({
    super.key,
    required this.phoneController,
    required this.notesController,
    required this.airlineController,
  });

  final TextEditingController phoneController;
  final TextEditingController notesController;
  final TextEditingController airlineController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewRequestCubit>();
    final state = context.watch<NewRequestCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isFlight) ...[
          const FormSectionTitle('Cabin class'),
          OptionChips(
            options: RequestFormOptions.flightClasses,
            selected: state.travelClass,
            onSelected: cubit.setTravelClass,
          ),
          const FormSectionTitle('Preferences', optional: true),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChipPill(
                label: 'Non-stop only',
                icon: Symbols.trending_flat_rounded,
                selected: state.directOnly,
                onTap: () => cubit.setDirectOnly(!state.directOnly),
              ),
              ChoiceChipPill(
                label: 'Flexible dates',
                icon: Symbols.date_range_rounded,
                selected: state.flexibleDates,
                onTap: () => cubit.setFlexibleDates(!state.flexibleDates),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Preferred airline',
            hint: 'Any airline',
            icon: Symbols.airlines_rounded,
            controller: airlineController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: cubit.setPreferredAirline,
          ),
        ],
        if (state.isTrain) ...[
          const FormSectionTitle('Class'),
          OptionChips(
            options: RequestFormOptions.trainClasses,
            selected: state.travelClass,
            onSelected: cubit.setTravelClass,
          ),
          const FormSectionTitle('Quota', optional: true),
          OptionChips(
            options: RequestFormOptions.quotas,
            selected: state.quota,
            onSelected: cubit.toggleQuota,
          ),
          const FormSectionTitle('Berth', optional: true),
          OptionChips(
            options: RequestFormOptions.berths,
            selected: state.berth,
            onSelected: cubit.toggleBerth,
          ),
        ],
        if (state.isHotel) ...[
          const FormSectionTitle('Room type', optional: true),
          OptionChips(
            options: RequestFormOptions.roomTypes,
            selected: state.roomType,
            onSelected: cubit.toggleRoomType,
          ),
          const FormSectionTitle('Star rating', optional: true),
          OptionChips(
            options: RequestFormOptions.starRatings,
            selected: state.starRating,
            onSelected: cubit.toggleStarRating,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ChoiceChipPill(
              label: 'Breakfast included',
              icon: Symbols.free_breakfast_rounded,
              selected: state.breakfast,
              onTap: () => cubit.setBreakfast(!state.breakfast),
            ),
          ),
        ],
        FormSectionTitle(state.isHotel ? 'Guests' : 'Who is travelling'),
        _PeopleCard(state: state),
        const FormSectionTitle('Notes for agents', optional: true),
        AppTextField(
          label: 'Anything agents should know',
          hint: state.isHotel
              ? 'Sea view, late check-in, near the beach…'
              : state.isTrain
              ? 'Preferred train, timing, food…'
              : 'Morning flights, extra baggage, meals…',
          controller: notesController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: cubit.setNotes,
        ),
        const FormSectionTitle('Contact'),
        AppTextField(
          fieldKey: const Key('contact-phone'),
          label: 'Mobile number',
          hint: 'e.g. 98100 43210',
          icon: Symbols.call_rounded,
          controller: phoneController,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          onChanged: cubit.setPhone,
        ),
        FieldError(state.errors[RequestField.phone]),
        const SizedBox(height: 12),
        _ReadOnlyField(
          label: 'Email',
          icon: Symbols.mail_rounded,
          value: state.email,
        ),
        const FormSectionTitle('Review'),
        _ReviewCard(state: state),
      ],
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.state});

  final NewRequestState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewRequestCubit>();
    final rows = <(Counter, String, String)>[
      (Counter.adults, 'Adults', state.isTrain ? '12–59 years' : '12+ years'),
      if (state.isTrain) (Counter.seniors, 'Seniors', '60+ years'),
      (Counter.children, 'Children', '2–11 years'),
      if (state.isFlight) (Counter.infants, 'Infants', 'Under 2, on a lap'),
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      radius: 20,
      child: Column(
        children: [
          for (final (i, (counter, label, hint)) in rows.indexed) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: '$label, $hint: ${state.count(counter)}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppTypography.body(
                              15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            hint,
                            style: AppTypography.body(
                              12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${state.count(counter)}',
                      textAlign: TextAlign.center,
                      style: AppTypography.number(17, tracking: 0),
                    ),
                  ),
                  CountStepper(
                    label: label.toLowerCase(),
                    value: state.count(counter),
                    min: cubit.bounds(counter).$1,
                    max: cubit.bounds(counter).$2,
                    onChanged: (v) =>
                        cubit.changeCount(counter, v - state.count(counter)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      readOnly: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.body(13, weight: FontWeight.w600)),
          const SizedBox(height: 7),
          Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.sunken,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      16,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Icon(
                  Symbols.lock_rounded,
                  size: 16,
                  color: AppColors.textFaint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.state});

  final NewRequestState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final from = s.from;
    final to = s.to;
    final area = s.area.trim();
    final route = s.isHotel
        ? [
            if (area.isNotEmpty) area,
            if (from != null) placeTitle(from),
          ].join(', ')
        : '${from == null ? '—' : placeTitle(from)} → '
              '${to == null ? '—' : placeTitle(to)}';

    final depart = s.departDate;
    final ret = s.returnDate;
    final String when;
    if (depart == null) {
      when = '—';
    } else if (s.isHotel && ret != null) {
      when =
          '${Fmt.dayMonth(depart)} – ${Fmt.dayMonth(ret)} · '
          '${s.nights} ${s.nights == 1 ? 'night' : 'nights'}';
    } else if (s.isFlight && s.roundTrip && ret != null) {
      when = '${Fmt.dayMonth(depart)} – ${Fmt.dayMonth(ret)} · round-trip';
    } else {
      when = Fmt.weekdayDayMonth(depart);
    }

    final people = Fmt.people(
      adults: s.adults,
      children: s.children,
      infants: s.isFlight ? s.infants : 0,
      seniors: s.isTrain ? s.seniors : 0,
    );

    final extras = [
      if (s.isHotel) ...[
        if (RequestFormOptions.label(RequestFormOptions.roomTypes, s.roomType)
            case final room?)
          room,
        if (s.starRating != null) '${s.starRating}★',
        if (s.breakfast) 'breakfast',
      ] else
        Fmt.travelClass(s.travelClass),
      if (s.isFlight && s.directOnly) 'non-stop',
      if (s.isFlight && s.flexibleDates) 'flexible dates',
      if (s.isTrain)
        if (RequestFormOptions.label(RequestFormOptions.quotas, s.quota)
            case final quota?)
          '$quota quota',
    ].join(' · ');

    return AppCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: s.type.icon, tint: s.type.tint, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  route,
                  style: AppTypography.body(16, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ReviewLine(icon: Symbols.calendar_month_rounded, text: when),
          _ReviewLine(
            icon: Symbols.group_rounded,
            text: s.isHotel
                ? '$people · ${s.rooms} ${s.rooms == 1 ? 'room' : 'rooms'}'
                : people,
          ),
          if (extras.isNotEmpty)
            _ReviewLine(icon: Symbols.tune_rounded, text: extras),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.isHotel ? 'Budget · total stay' : 'Budget · total',
                  style: AppTypography.body(13, color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Fmt.inr(s.budget),
                    style: AppTypography.number(22),
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

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(14, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
