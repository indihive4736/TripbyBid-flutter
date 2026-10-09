import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/ink_panel.dart';
import '../../../domain/entities/trip_detail.dart';
import '../../../domain/entities/trip_request.dart';
import '../../widgets/trip_style.dart';
import '../detail_labels.dart';

/// The navy header: back / id / share, status, route, date and the three
/// stat tiles (budget, best bid or fare, saving).
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.detail,
    required this.onBack,
    required this.onCopyId,
    required this.onShare,
  });

  final TripDetail detail;
  final VoidCallback onBack;
  final VoidCallback onCopyId;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final request = detail.request;
    final status = headerStatus(detail);
    final top = MediaQuery.paddingOf(context).top;
    return InkPanel(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 22),
      glowSize: 340,
      glowOpacity: 0.42,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconButton(
                icon: Symbols.arrow_back_rounded,
                tooltip: 'Back',
                onInk: true,
                onPressed: onBack,
              ),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Copy booking ID ${detail.reference}',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: onCopyId,
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  detail.reference,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.eyebrow(
                                    size: 12,
                                    color: AppColors.onInkSecondary,
                                    tracking: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Symbols.content_copy_rounded,
                                size: 14,
                                color: AppColors.onInkSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AppIconButton(
                icon: Symbols.ios_share_rounded,
                tooltip: 'Share trip',
                onInk: true,
                onPressed: onShare,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(label: status.label, bg: status.bg, fg: status.fg),
              Text(
                status.sub,
                style: AppTypography.body(12, color: AppColors.onInkTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Route(request: request),
          const SizedBox(height: 8),
          Text(
            _dateLine(request),
            style: AppTypography.body(14, color: AppColors.onInkSecondary),
          ),
          const SizedBox(height: 18),
          _Stats(detail: detail),
        ],
      ),
    );
  }

  static String _dateLine(TripRequest request) {
    if (request.type == TripType.hotel) return request.whenLine;
    final d = request.details;
    final dates = request.returnDate == null
        ? Fmt.weekdayDayMonth(request.departDate)
        : '${Fmt.dayMonth(request.departDate)} – '
              '${Fmt.dayMonth(request.returnDate!)}';
    return [
      dates,
      if (d != null)
        Fmt.people(
          adults: d.adults,
          children: d.children,
          infants: d.infants,
          seniors: d.seniors,
        ),
      if (d?.travelClass != null && d!.travelClass!.isNotEmpty)
        Fmt.travelClass(d.travelClass),
    ].join(' · ');
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.body(12, color: fg, weight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Big BOM ✈ DXB codes, or the title when the route has no codes (hotels).
class _Route extends StatelessWidget {
  const _Route({required this.request});

  final TripRequest request;

  static String _city(String? city, String location) {
    if (city != null && city.isNotEmpty) return city;
    return location.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final codes = request.type == TripType.hotel ? null : request.codes;
    if (codes == null) {
      return Text(
        request.title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.display(
          34,
          color: AppColors.onInk,
        ).copyWith(height: 1.05, letterSpacing: -0.045 * 34),
      );
    }
    final d = request.details;
    final codeStyle = AppTypography.number(
      42,
      color: AppColors.onInk,
      tracking: -0.045,
    ).copyWith(height: 1);
    final cityStyle = AppTypography.body(13, color: AppColors.onInkTertiary);
    final middle = switch (d?.tripType) {
      'round-trip' => 'ROUND TRIP',
      'multi-city' => 'MULTI-CITY',
      _ => request.type.label.toUpperCase(),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(child: Text(codes.$1, style: codeStyle)),
              const SizedBox(height: 4),
              Text(
                _city(d?.fromCity, request.fromLocation),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cityStyle,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
            child: Column(
              children: [
                Transform.rotate(
                  angle: request.type == TripType.flight ? 1.5708 : 0,
                  child: Icon(
                    request.type.icon,
                    size: 22,
                    color: AppColors.accentLight,
                  ),
                ),
                const SizedBox(height: 4),
                const DashedLine(color: Color(0x4DF3EDE3)),
                const SizedBox(height: 4),
                Text(
                  middle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.eyebrow(
                    size: 11,
                    color: AppColors.onInkTertiary,
                    tracking: 0.04,
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(child: Text(codes.$2, style: codeStyle)),
              const SizedBox(height: 4),
              Text(
                _city(d?.toCity, request.toLocation),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: cityStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.detail});

  final TripDetail detail;

  @override
  Widget build(BuildContext context) {
    final budget = detail.request.budget;
    final accepted = detail.hasAgent;
    final price = accepted ? detail.fare : detail.bestBid?.price;
    final save = price != null && budget > 0 && price < budget
        ? '${((1 - price / budget) * 100).round()}%'
        : null;
    return Row(
      children: [
        Expanded(
          child: _Tile(label: 'Budget', value: Fmt.inr(budget)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tile(
            label: accepted ? 'Your fare' : 'Best bid',
            value: price == null ? null : Fmt.inr(price),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tile(label: 'You save', value: save, mint: save != null),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.mint = false});

  final String label;
  final String? value;
  final bool mint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: mint ? const Color(0x247FD6AE) : const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mint ? const Color(0x407FD6AE) : const Color(0x1AFFFFFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(11, color: AppColors.onInkTertiary),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value ?? '—',
              style: AppTypography.number(
                18,
                tracking: -0.03,
                color: value == null
                    ? AppColors.onInkFaint
                    : mint
                    ? AppColors.mint
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
