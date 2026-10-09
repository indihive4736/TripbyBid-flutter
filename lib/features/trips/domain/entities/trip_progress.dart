import 'trip_detail.dart';
import 'trip_stage.dart';

/// The five milestones of a booking, in order.
enum TripStep { posted, bids, accepted, paid, ticketed }

/// How one [TripStep] shows in the progress card.
enum TripStepStatus {
  done,
  current,
  upcoming,

  /// The trip was cancelled or expired: only the start is marked.
  muted,
}

/// Where a trip is on the Posted · Bids · Accepted · Paid · Ticketed track.
final class TripProgress {
  const TripProgress({required this.done, this.current, this.muted = false});

  factory TripProgress.of(TripStage stage) => switch (stage) {
    TripStage.awaitingBids ||
    TripStage.bidsIn => const TripProgress(done: 1, current: TripStep.bids),
    TripStage.paymentDue => const TripProgress(done: 3, current: TripStep.paid),
    TripStage.awaitingConfirmation ||
    TripStage.awaitingTicket ||
    TripStage.needsAttention => const TripProgress(
      done: 4,
      current: TripStep.ticketed,
    ),
    TripStage.ticketReady || TripStage.completed => const TripProgress(done: 5),
    TripStage.cancelled ||
    TripStage.expired => const TripProgress(done: 0, muted: true),
  };

  /// Steps completed from the start.
  final int done;

  /// The step the trip is waiting on, if any.
  final TripStep? current;

  /// Cancelled or expired.
  final bool muted;

  TripStepStatus statusOf(TripStep step) {
    if (muted) {
      return step == TripStep.posted
          ? TripStepStatus.muted
          : TripStepStatus.upcoming;
    }
    if (step.index < done) return TripStepStatus.done;
    if (step == current) return TripStepStatus.current;
    return TripStepStatus.upcoming;
  }

  @override
  bool operator ==(Object other) =>
      other is TripProgress &&
      other.done == done &&
      other.current == current &&
      other.muted == muted;

  @override
  int get hashCode => Object.hash(done, current, muted);

  @override
  String toString() =>
      'TripProgress(done: $done, current: $current'
      '${muted ? ', muted' : ''})';
}

enum TimelineKind {
  // What happened.
  posted,
  bidsReceived,
  accepted,
  paid,
  ticketIssued,
  completed,
  cancelled,
  expired,

  // What comes next ("UP NEXT").
  bidsArrive,
  acceptBid,
  payToConfirm,
  agentConfirms,
  ticketComing,
  checkTicket,
  fixPending,
}

/// One entry of the booking timeline. Pending entries ([upNext]) describe
/// the next milestone and carry no time.
final class TimelineEvent {
  const TimelineEvent(
    this.kind, {
    this.at,
    this.upNext = false,
    this.amount,
    this.count,
    this.agentName,
    this.until,
    this.note,
  });

  final TimelineKind kind;

  /// When it happened, when known.
  final DateTime? at;
  final bool upNext;

  /// Best offer (bids), amount paid (payment, cancellation of a paid booking).
  final double? amount;

  /// Number of bids.
  final int? count;
  final String? agentName;

  /// Payment deadline of an accepted offer.
  final DateTime? until;

  /// Booking reference, ticket file name or cancellation reason.
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is TimelineEvent &&
      other.kind == kind &&
      other.at == at &&
      other.upNext == upNext &&
      other.amount == amount &&
      other.count == count &&
      other.agentName == agentName &&
      other.until == until &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(kind, at, upNext, amount, count, agentName, until, note);

  @override
  String toString() =>
      'TimelineEvent($kind${upNext ? ', up next' : ''}, at: $at)';
}

/// Derives the booking timeline from what the API reports.
abstract final class TripTimeline {
  static List<TimelineEvent> of(TripDetail detail) {
    final request = detail.request;
    final booking = detail.booking;
    final stage = request.stage;
    final bids = detail.comparableBids;
    final chosen = detail.chosenBid;

    final events = <TimelineEvent>[
      TimelineEvent(
        TimelineKind.posted,
        at: request.createdAt,
        amount: request.budget,
      ),
    ];

    final count = bids.length > request.bidsCount
        ? bids.length
        : request.bidsCount;
    if (count > 0) {
      final best = bids.isEmpty ? null : bids.first;
      final first = bids.isEmpty
          ? null
          : bids
                .map((b) => b.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
      events.add(
        TimelineEvent(
          TimelineKind.bidsReceived,
          at: first,
          count: count,
          amount: best?.price,
          agentName: best?.agentName,
        ),
      );
    }

    final agentName = booking?.agent?.displayName ?? chosen?.agentName;
    if (chosen != null || booking != null) {
      events.add(
        TimelineEvent(
          TimelineKind.accepted,
          at: chosen?.acceptedAt,
          agentName: agentName,
          until: booking == null ? chosen?.paymentDueAt : null,
        ),
      );
    }

    if (booking != null) {
      events.add(
        TimelineEvent(
          TimelineKind.paid,
          at: booking.paymentDate ?? booking.createdAt,
          amount: booking.price,
          note: booking.referenceNumber,
        ),
      );
      final ticket = booking.ticket;
      if (ticket != null) {
        events.add(
          TimelineEvent(
            TimelineKind.ticketIssued,
            at: ticket.uploadedAt,
            note: ticket.fileName,
          ),
        );
      }
    }

    switch (stage) {
      case TripStage.completed:
        events.add(
          TimelineEvent(
            TimelineKind.completed,
            at: booking?.completedAt,
            agentName: agentName,
          ),
        );
      case TripStage.cancelled:
        events.add(
          TimelineEvent(
            TimelineKind.cancelled,
            at: booking?.cancelledAt,
            amount: booking?.price,
            note: booking?.cancellationReason,
          ),
        );
      case TripStage.expired:
        events.add(TimelineEvent(TimelineKind.expired, at: request.expiresAt));
      case TripStage.awaitingBids:
        events.add(const TimelineEvent(TimelineKind.bidsArrive, upNext: true));
      case TripStage.bidsIn:
        events.add(const TimelineEvent(TimelineKind.acceptBid, upNext: true));
      case TripStage.paymentDue:
        events.add(
          TimelineEvent(
            TimelineKind.payToConfirm,
            upNext: true,
            until: chosen?.paymentDueAt,
          ),
        );
      case TripStage.awaitingConfirmation:
        events.add(
          TimelineEvent(
            TimelineKind.agentConfirms,
            upNext: true,
            agentName: agentName,
          ),
        );
      case TripStage.awaitingTicket:
        events.add(
          TimelineEvent(
            TimelineKind.ticketComing,
            upNext: true,
            agentName: agentName,
          ),
        );
      case TripStage.ticketReady:
        events.add(const TimelineEvent(TimelineKind.checkTicket, upNext: true));
      case TripStage.needsAttention:
        events.add(
          TimelineEvent(
            TimelineKind.fixPending,
            upNext: true,
            agentName: agentName,
          ),
        );
    }
    return events;
  }
}
