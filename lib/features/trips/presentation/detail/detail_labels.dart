import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/bid.dart';
import '../../domain/entities/trip_detail.dart';
import '../../domain/entities/trip_progress.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/entities/trip_stage.dart';
import '../widgets/trip_style.dart';
import 'trip_detail_cubit.dart';

/// Display helpers for the booking-detail screen.
extension TripDetailDisplay on TripDetail {
  TripStage get stage => request.stage;

  /// A bid was accepted or paid for.
  bool get hasAgent => chosenBid != null || booking != null;

  /// The agent (agency) the trip is booked with.
  String? get agentName => booking?.agent?.displayName ?? chosenBid?.agentName;

  String? get agentFirstName => agentName?.trim().split(RegExp(r'\s+')).first;

  double get agentRating {
    final rating = booking?.agent?.rating ?? 0;
    return rating > 0 ? rating : chosenBid?.agentRating ?? 0;
  }

  bool get agentVerified =>
      (booking?.agent?.verified ?? false) ||
      (chosenBid?.agentVerified ?? false);

  /// The accepted or paid price.
  double? get fare => booking?.price ?? chosenBid?.price;

  /// Reference shown in the header: the booking reference, else the short id.
  String get reference {
    final ref = booking?.referenceNumber;
    return ref == null || ref.isEmpty ? request.shortId : ref;
  }

  /// Text copied by the share button.
  String get shareText =>
      'TripByBid $reference · ${request.title} · '
      '${Fmt.weekdayDayMonth(request.departDate)}';

  /// The new-request type for "post a similar request".
  String get requestType =>
      request.type == TripType.package ? 'flight' : request.type.apiValue;
}

/// Header status pill: label, colours (on ink) and the line beside it.
({String label, Color bg, Color fg, String sub}) headerStatus(
  TripDetail detail, {
  DateTime? now,
}) {
  final request = detail.request;
  final booking = detail.booking;
  String posted() {
    final rel = Fmt.relative(request.createdAt, now: now);
    final soft = RegExp(r'^\d').hasMatch(rel)
        ? rel
        : rel[0].toLowerCase() + rel.substring(1);
    return 'Posted $soft';
  }

  String refLine(String fallback) {
    final ref = booking?.referenceNumber;
    return ref == null || ref.isEmpty ? fallback : 'Ref $ref';
  }

  const green = (AppColors.successTint, AppColors.successOnTint);
  final count = detail.activeBids.length > request.bidsCount
      ? detail.activeBids.length
      : request.bidsCount;
  final (label, (bg, fg), sub) = switch (request.stage) {
    TripStage.awaitingBids => (
      'Awaiting bids',
      (AppColors.muted, AppColors.ink),
      posted(),
    ),
    TripStage.bidsIn => (
      '$count ${count == 1 ? 'bid' : 'bids'} · pick one',
      (AppColors.accent, AppColors.ink),
      detail.bestBid == null
          ? posted()
          : 'Best ${Fmt.inr(detail.bestBid!.price)}',
    ),
    TripStage.paymentDue => (
      'Payment due',
      (AppColors.accentTint, AppColors.accentOnTint),
      'Fare held by ${detail.agentFirstName ?? 'your agent'}',
    ),
    TripStage.awaitingConfirmation => (
      'Awaiting confirmation',
      (AppColors.yellowTint, AppColors.ink),
      refLine('Agent is confirming'),
    ),
    TripStage.awaitingTicket => (
      'Confirmed',
      green,
      refLine('Ticket on the way'),
    ),
    TripStage.ticketReady => ('Ticket issued', green, 'Check your ticket'),
    TripStage.needsAttention => (
      'Needs attention',
      (AppColors.dangerTint, AppColors.accentOnTint),
      request.status == 'needs_correction'
          ? 'Correction requested'
          : 'Support ticket open',
    ),
    TripStage.completed => (
      'Completed',
      green,
      'Travelled ${Fmt.dayMonth(request.departDate)}',
    ),
    TripStage.cancelled => (
      'Cancelled',
      (AppColors.dangerTint, AppColors.accentOnTint),
      booking != null ? 'Refund initiated' : 'No charges',
    ),
    TripStage.expired => (
      'Expired',
      (AppColors.muted, AppColors.ink),
      'No charges',
    ),
  };
  return (label: label, bg: bg, fg: fg, sub: sub);
}

/// "★ 4.9 · 312 trips" — the part after the star.
String bidStats(Bid bid) {
  final rating = bid.agentRating > 0
      ? bid.agentRating.toStringAsFixed(1)
      : 'New';
  final trips = bid.agentTrips;
  if (trips != null) return '$rating · $trips ${trips == 1 ? 'trip' : 'trips'}';
  if (bid.agentReviews > 0) {
    return '$rating · ${bid.agentReviews} '
        '${bid.agentReviews == 1 ? 'review' : 'reviews'}';
  }
  return rating;
}

/// One row of the trip details list.
typedef DetailRow = ({IconData icon, String label, String value});

/// The request's details for the overview and the summary sheet.
List<DetailRow> requestDetailRows(TripRequest request) {
  final d = request.details;
  final hotel = request.type == TripType.hotel;
  final rows = <DetailRow>[
    (
      icon: Symbols.calendar_month_rounded,
      label: hotel ? 'Check-in' : 'Date',
      value: Fmt.weekdayDayMonth(request.departDate),
    ),
    if (request.returnDate != null)
      (
        icon: hotel
            ? Symbols.event_available_rounded
            : Symbols.event_repeat_rounded,
        label: hotel ? 'Check-out' : 'Return',
        value: Fmt.weekdayDayMonth(request.returnDate!),
      ),
  ];
  if (hotel && request.returnDate != null) {
    final nights = request.returnDate!.difference(request.departDate).inDays;
    rows.add((
      icon: Symbols.dark_mode_rounded,
      label: 'Nights',
      value: '$nights',
    ));
  }
  if (d != null) {
    if (hotel) {
      if (d.rooms != null) {
        rows.add((
          icon: Symbols.bed_rounded,
          label: 'Rooms',
          value: '${d.rooms}',
        ));
      }
      if (d.roomType != null && d.roomType!.isNotEmpty) {
        rows.add((
          icon: Symbols.king_bed_rounded,
          label: 'Room type',
          value: Fmt.travelClass(d.roomType),
        ));
      }
      if (d.starRating != null) {
        rows.add((
          icon: Symbols.star_rounded,
          label: 'Hotel rating',
          value: '${d.starRating}-star',
        ));
      }
    } else {
      if (d.travelClass != null && d.travelClass!.isNotEmpty) {
        rows.add((
          icon: Symbols.airline_seat_recline_normal_rounded,
          label: 'Class',
          value: Fmt.travelClass(d.travelClass),
        ));
      }
      if (d.tripType != null && d.tripType!.isNotEmpty) {
        rows.add((
          icon: Symbols.swap_horiz_rounded,
          label: 'Trip type',
          value: Fmt.travelClass(d.tripType),
        ));
      }
    }
    rows.add((
      icon: Symbols.group_rounded,
      label: hotel ? 'Guests' : 'Travellers',
      value: Fmt.people(
        adults: d.adults,
        children: d.children,
        infants: d.infants,
        seniors: d.seniors,
      ),
    ));
    if (d.preferredAirline != null && d.preferredAirline!.isNotEmpty) {
      rows.add((
        icon: Symbols.flight_class_rounded,
        label: 'Airline',
        value: d.preferredAirline!,
      ));
    }
    if (d.quota != null && d.quota!.isNotEmpty) {
      rows.add((
        icon: Symbols.confirmation_number_rounded,
        label: 'Quota',
        value: Fmt.travelClass(d.quota),
      ));
    }
  }
  final notes = request.requirements?.trim();
  if (notes != null && notes.isNotEmpty) {
    rows.add((
      icon: Symbols.sticky_note_2_rounded,
      label: 'Notes',
      value: notes,
    ));
  }
  return rows;
}

/// Icon, title and subtitle of a timeline entry.
({IconData icon, String title, String sub}) timelineText(TimelineEvent e) {
  final agent = e.agentName ?? 'your agent';
  return switch (e.kind) {
    TimelineKind.posted => (
      icon: Symbols.edit_note_rounded,
      title: 'Request posted',
      sub: e.amount == null
          ? 'Sent to verified agents'
          : 'Budget ${Fmt.inr(e.amount!)} · sent to verified agents',
    ),
    TimelineKind.bidsReceived => (
      icon: Symbols.gavel_rounded,
      title: '${e.count} ${e.count == 1 ? 'bid' : 'bids'} received',
      sub: e.amount == null
          ? 'Compare them in Bids'
          : 'Best offer ${Fmt.inr(e.amount!)}'
                '${e.agentName == null ? '' : ' from ${e.agentName}'}',
    ),
    TimelineKind.accepted => (
      icon: Symbols.handshake_rounded,
      title: 'You accepted $agent',
      sub: e.until == null
          ? 'Fare held for payment'
          : 'Fare held until ${Fmt.dateTime(e.until!)}',
    ),
    TimelineKind.paid => (
      icon: Symbols.payments_rounded,
      title: 'Payment successful',
      sub: [
        if (e.amount != null) '${Fmt.inr(e.amount!)} paid',
        if (e.note != null && e.note!.isNotEmpty) 'Ref ${e.note}',
      ].join(' · '),
    ),
    TimelineKind.ticketIssued => (
      icon: Symbols.confirmation_number_rounded,
      title: 'E-ticket issued',
      sub: e.note ?? 'Open it in Docs',
    ),
    TimelineKind.completed => (
      icon: Symbols.flight_land_rounded,
      title: 'Trip completed',
      sub: 'Ticket confirmed with $agent',
    ),
    TimelineKind.cancelled => (
      icon: Symbols.event_busy_rounded,
      title: e.amount == null ? 'Request cancelled' : 'Booking cancelled',
      sub: [
        e.amount == null ? 'Nothing was charged' : 'Refund initiated',
        if (e.note != null && e.note!.isNotEmpty) e.note!,
      ].join(' · '),
    ),
    TimelineKind.expired => (
      icon: Symbols.timer_off_rounded,
      title: 'Request expired',
      sub: 'No offer was booked in time',
    ),
    TimelineKind.bidsArrive => (
      icon: Symbols.gavel_rounded,
      title: 'Bids arrive',
      sub: 'Usually within minutes',
    ),
    TimelineKind.acceptBid => (
      icon: Symbols.handshake_rounded,
      title: 'Accept a bid',
      sub: 'Pick the offer you like',
    ),
    TimelineKind.payToConfirm => (
      icon: Symbols.payments_rounded,
      title: 'Pay to confirm',
      sub: e.until == null
          ? 'Before the fare hold ends'
          : 'Before ${Fmt.dateTime(e.until!)}',
    ),
    TimelineKind.agentConfirms => (
      icon: Symbols.verified_rounded,
      title: 'Agent confirms',
      sub: '$agent confirms your booking',
    ),
    TimelineKind.ticketComing => (
      icon: Symbols.confirmation_number_rounded,
      title: 'E-ticket',
      sub: '$agent is issuing your ticket',
    ),
    TimelineKind.checkTicket => (
      icon: Symbols.fact_check_rounded,
      title: 'Check your ticket',
      sub: 'Confirm it or ask for a fix',
    ),
    TimelineKind.fixPending => (
      icon: Symbols.build_rounded,
      title: 'Agent reviews your request',
      sub: 'You will get an updated ticket',
    ),
  };
}

/// The toast icon for a notice.
IconData noticeIcon(NoticeIcon icon) => switch (icon) {
  NoticeIcon.success => Symbols.check_rounded,
  NoticeIcon.accepted => Symbols.handshake_rounded,
  NoticeIcon.paid => Symbols.check_circle_rounded,
  NoticeIcon.payCancelled => Symbols.close_rounded,
  NoticeIcon.released => Symbols.undo_rounded,
  NoticeIcon.cancelled => Symbols.event_busy_rounded,
  NoticeIcon.edited => Symbols.edit_rounded,
  NoticeIcon.rated => Symbols.star_rounded,
  NoticeIcon.refund => Symbols.currency_exchange_rounded,
  NoticeIcon.error => Symbols.error_rounded,
};
