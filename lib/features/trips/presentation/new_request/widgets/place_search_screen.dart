import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/headings.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../domain/entities/new_trip_request.dart';
import '../../../domain/entities/trip_request.dart';
import '../../widgets/trip_style.dart';
import '../place_search_cubit.dart';

/// Opens the full-screen place picker for [type] and returns the choice.
Future<Place?> pickPlace(
  BuildContext context, {
  required TripType type,
  required String title,
}) {
  final cubit = context.read<PlaceSearchCubit>();
  unawaited(cubit.open(type));
  return Navigator.of(context).push<Place>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: PlaceSearchScreen(title: title),
      ),
    ),
  );
}

/// Search field with autofocus and a ranked results list; tapping a result
/// pops it.
class PlaceSearchScreen extends StatelessWidget {
  const PlaceSearchScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final type = context.select((PlaceSearchCubit c) => c.state.type);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Symbols.close_rounded,
                    tooltip: 'Close',
                    size: 44,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.title(22),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: _SearchField(type: type),
            ),
            const Expanded(child: _Results()),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.type});

  final TripType type;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _hint => switch (widget.type) {
    TripType.train => 'Station name or code',
    TripType.hotel => 'Search a city',
    _ => 'City, airport or code',
  };

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.words,
      style: AppTypography.body(16, weight: FontWeight.w600),
      onChanged: (text) {
        setState(() {});
        context.read<PlaceSearchCubit>().search(text);
      },
      decoration: InputDecoration(
        hintText: _hint,
        prefixIcon: const Icon(Symbols.search_rounded, size: 22),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Symbols.close_rounded, size: 20),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  context.read<PlaceSearchCubit>().search('');
                },
              ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlaceSearchCubit>().state;
    final Widget body = switch (state.status) {
      PlaceSearchStatus.failure => SingleChildScrollView(
        child: StateMessage.error(
          message: state.message ?? 'Could not load places.',
          onRetry: () => context.read<PlaceSearchCubit>().retry(),
        ),
      ),
      PlaceSearchStatus.loading when state.results.isEmpty =>
        const LoadingView(),
      _ when state.results.isEmpty => const SingleChildScrollView(
        child: StateMessage(
          icon: Symbols.travel_explore_rounded,
          title: 'No matches',
          message: 'Try a city name or a code like BOM.',
        ),
      ),
      _ => ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        itemCount: state.results.length + 1,
        separatorBuilder: (_, i) =>
            i == 0 ? const SizedBox(height: 6) : const Divider(indent: 66),
        itemBuilder: (context, i) => i == 0
            ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Eyebrow(
                  state.showingPopular ? 'Popular' : 'Best matches',
                  color: AppColors.textTertiary,
                ),
              )
            : _PlaceRow(place: state.results[i - 1], type: state.type),
      ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: KeyedSubtree(key: ValueKey(state.status), child: body),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.type});

  final Place place;
  final TripType type;

  @override
  Widget build(BuildContext context) {
    final code = place.code;
    final subtitle = [
      if (type != TripType.hotel && place.city != null) place.city!,
      if (countryName(place.country) case final c?) c,
    ].join(', ');
    return InkWell(
      onTap: () => Navigator.of(context).pop(place),
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: type.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: code == null
                    ? const Icon(
                        Symbols.location_city_rounded,
                        size: 20,
                        color: AppColors.ink,
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            code,
                            style: AppTypography.number(13, tracking: 0),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(15, weight: FontWeight.w700),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          13,
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
    );
  }
}

/// "IN" → "India"; other ISO codes as they are.
String? countryName(String? iso) => switch (iso) {
  null || '' => null,
  'IN' => 'India',
  'AE' => 'United Arab Emirates',
  'US' => 'United States',
  'GB' => 'United Kingdom',
  'SG' => 'Singapore',
  'TH' => 'Thailand',
  'NP' => 'Nepal',
  'LK' => 'Sri Lanka',
  _ => iso,
};
