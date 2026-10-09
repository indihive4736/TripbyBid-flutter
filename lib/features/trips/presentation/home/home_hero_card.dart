import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/headings.dart';
import '../../../../core/widgets/ink_panel.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/entities/trip_summaries.dart';
import '../widgets/trip_style.dart';

/// The navy hero on the home screen: the featured trip, or an invitation to
/// post a first request.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    super.key,
    required this.highlight,
    required this.today,
    required this.onOpen,
  });

  final TripHighlight? highlight;
  final DateTime today;

  /// Navigates to [route]; the home screen refreshes when it returns.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final h = highlight;
    if (h == null) return _EmptyHero(onOpen: onOpen);
    final trip = h.trip;

    final (eyebrow, chip, cta, route) = switch (h.kind) {
      HighlightKind.paymentDue => (
        'Pay to confirm',
        'Payment due',
        'Pay to confirm',
        AppRoutes.trip(trip.id),
      ),
      HighlightKind.upcoming => (
        _countdown(TripSummaries.daysUntil(trip.departDate, today: today)),
        trip.stage.pillLabel(bidsCount: trip.bidsCount),
        'View booking',
        AppRoutes.trip(trip.id),
      ),
      HighlightKind.bidsIn => (
        '${trip.bidsCount} ${trip.bidsCount == 1 ? 'bid' : 'bids'} · live',
        trip.type.label,
        'Compare bids',
        AppRoutes.trip(trip.id, tab: 'bids'),
      ),
    };

    return InkPanel(
      glow: const Alignment(1.1, -1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PulseDot(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: AppTypography.eyebrow(color: AppColors.accentSoft),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chip,
                  style: AppTypography.body(
                    12,
                    color: AppColors.onInk,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Route(trip: trip),
          const SizedBox(height: 18),
          _Facts(trip: trip),
          const SizedBox(height: 16),
          AppButton(
            label: cta,
            icon: Symbols.arrow_forward_rounded,
            height: 50,
            onPressed: () => onOpen(route),
          ),
        ],
      ),
    );
  }

  static String _countdown(int days) => switch (days) {
    <= 0 => 'Next trip · today',
    1 => 'Next trip · tomorrow',
    _ => 'Next trip · in $days days',
  };
}

/// Big codes with the journey line between them, or the title when there
/// are no codes (hotels, free-text places).
class _Route extends StatelessWidget {
  const _Route({required this.trip});

  final TripRequest trip;

  @override
  Widget build(BuildContext context) {
    final codes = trip.codes;
    if (codes == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(28, color: AppColors.onInk),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(trip.type.icon, size: 16, color: AppColors.accentLight),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  trip.whenLine,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(13, color: AppColors.onInkTertiary),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final d = trip.details;
    final (fromCode, toCode) = codes;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _End(
          code: fromCode,
          place: d?.fromCity ?? _place(trip.fromLocation),
          alignEnd: false,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
            child: Column(
              children: [
                Transform.rotate(
                  angle: trip.type == TripType.flight ? math.pi / 2 : 0,
                  child: Icon(
                    trip.type.icon,
                    size: 22,
                    color: AppColors.accentLight,
                  ),
                ),
                const SizedBox(height: 4),
                const DashedLine(color: Color(0x4DF3EDE3)),
              ],
            ),
          ),
        ),
        _End(
          code: toCode,
          place: d?.toCity ?? _place(trip.toLocation),
          alignEnd: true,
        ),
      ],
    );
  }

  static String _place(String label) =>
      label.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
}

class _End extends StatelessWidget {
  const _End({required this.code, required this.place, required this.alignEnd});

  final String code;
  final String place;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code,
              maxLines: 1,
              style: AppTypography.number(
                40,
                color: AppColors.onInk,
              ).copyWith(height: 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: AppTypography.body(13, color: AppColors.onInkTertiary),
          ),
        ],
      ),
    );
  }
}

/// Date, departure/stay detail and fare under a dashed rule.
class _Facts extends StatelessWidget {
  const _Facts({required this.trip});

  final TripRequest trip;

  @override
  Widget build(BuildContext context) {
    final d = trip.details;
    final isHotel = trip.type == TripType.hotel;
    final departs = d?.preferredDepartureTime;
    final nights = trip.returnDate?.difference(trip.departDate).inDays;
    final booking = trip.booking;

    final facts = <(String, String)>[
      (isHotel ? 'Check-in' : 'Date', Fmt.dayMonth(trip.departDate)),
      if (isHotel && nights != null && nights > 0)
        ('Nights', '$nights')
      else if (departs != null && departs.isNotEmpty)
        ('Departs', departs[0].toUpperCase() + departs.substring(1))
      else if (d != null)
        ('Travellers', '${d.travellers}'),
      if (booking != null)
        ('Fare', Fmt.inr(booking.price))
      else
        ('Budget', Fmt.inr(trip.budget)),
    ];

    return Column(
      children: [
        const DashedLine(color: Color(0x2EF3EDE3), thickness: 1),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in facts)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body(
                        11,
                        color: AppColors.onInkTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.number(
                        15,
                        color: AppColors.onInk,
                        tracking: -0.02,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return InkPanel(
      glow: const Alignment(1.1, -1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Eyebrow('Your first trip', color: AppColors.accentSoft),
          ),
          const SizedBox(height: 16),
          const DisplayHeading(
            lead: 'Name your trip. Let agents ',
            accent: 'bid.',
            size: 30,
            color: AppColors.onInk,
            accentColor: AppColors.accentSoft,
          ),
          const SizedBox(height: 10),
          Text(
            'Post one request — verified travel agents compete with their '
            'best fares, and you pick.',
            style: AppTypography.body(
              14,
              color: AppColors.onInkSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Post a request',
            icon: Symbols.arrow_forward_rounded,
            height: 50,
            onPressed: () => onOpen(AppRoutes.newRequest),
          ),
        ],
      ),
    );
  }
}
