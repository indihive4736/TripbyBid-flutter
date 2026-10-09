import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/entities/trip_stage.dart';

/// Icons and tints per trip type.
extension TripTypeStyle on TripType {
  IconData get icon => switch (this) {
    TripType.flight => Symbols.flight_rounded,
    TripType.train => Symbols.train_rounded,
    TripType.hotel => Symbols.hotel_rounded,
    TripType.package => Symbols.beach_access_rounded,
  };

  Color get tint => switch (this) {
    TripType.flight => AppColors.flightTint,
    TripType.train => AppColors.trainTint,
    TripType.hotel => AppColors.hotelTint,
    TripType.package => AppColors.yellowTint,
  };

  String get label => switch (this) {
    TripType.flight => 'Flight',
    TripType.train => 'Train',
    TripType.hotel => 'Hotel',
    TripType.package => 'Package',
  };
}

/// Pill label and colours per stage (mirrors the web app's status groups).
extension TripStageStyle on TripStage {
  String pillLabel({int bidsCount = 0}) => switch (this) {
    TripStage.awaitingBids => 'Awaiting bids',
    TripStage.bidsIn => '$bidsCount ${bidsCount == 1 ? 'bid' : 'bids'}',
    TripStage.paymentDue => 'Payment due',
    TripStage.awaitingConfirmation => 'Awaiting confirmation',
    TripStage.awaitingTicket => 'Awaiting ticket',
    TripStage.ticketReady => 'Ticket issued',
    TripStage.needsAttention => 'Needs attention',
    TripStage.completed => 'Completed',
    TripStage.cancelled => 'Cancelled',
    TripStage.expired => 'Expired',
  };

  /// (background, foreground) on paper.
  (Color, Color) get pillColors => switch (this) {
    TripStage.awaitingBids => (AppColors.muted, AppColors.textSecondary),
    TripStage.bidsIn => (AppColors.accentTint, AppColors.accentOnTint),
    TripStage.paymentDue => (AppColors.ink, AppColors.accentSoft),
    TripStage.awaitingConfirmation ||
    TripStage.awaitingTicket => (const Color(0xFFDCE6F2), AppColors.inkRaised),
    TripStage.ticketReady ||
    TripStage.completed => (AppColors.successTint, AppColors.successOnTint),
    TripStage.needsAttention => (
      const Color(0xFFFDE2E2),
      const Color(0xFFB42318),
    ),
    TripStage.cancelled => (AppColors.dangerTint, AppColors.accentOnTint),
    TripStage.expired => (AppColors.muted, AppColors.textSecondary),
  };
}

extension TripRequestDisplay on TripRequest {
  /// "Mumbai → Dubai", or the hotel city.
  String get title {
    String clean(String place) =>
        place.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
    final from = clean(fromLocation);
    final to = clean(toLocation);
    if (type == TripType.hotel || to.isEmpty || from == to) {
      final area = details?.destinationArea;
      return area == null || area.isEmpty ? from : '$area, $from';
    }
    return '$from → $to';
  }

  /// "12 Nov · 2 adults" / "14–17 Dec · 3 nights".
  String get whenLine {
    final d = details;
    final people = d == null
        ? null
        : Fmt.people(
            adults: d.adults,
            children: d.children,
            infants: d.infants,
            seniors: d.seniors,
          );
    if (type == TripType.hotel && returnDate != null) {
      final nights = returnDate!.difference(departDate).inDays;
      return '${Fmt.dayMonth(departDate)} – ${Fmt.dayMonth(returnDate!)} · '
          '$nights ${nights == 1 ? 'night' : 'nights'}';
    }
    final dates = returnDate == null
        ? Fmt.dayMonth(departDate)
        : '${Fmt.dayMonth(departDate)} – ${Fmt.dayMonth(returnDate!)}';
    return people == null ? dates : '$dates · $people';
  }

  /// Airport/station codes for the big route header, when known.
  (String, String)? get codes {
    final d = details;
    final from = d?.fromCode ?? _codeIn(fromLocation);
    final to = d?.toCode ?? _codeIn(toLocation);
    return from != null && to != null ? (from, to) : null;
  }

  static String? _codeIn(String label) =>
      RegExp(r'\(([A-Z0-9]{2,5})\)\s*$').firstMatch(label)?.group(1);
}
