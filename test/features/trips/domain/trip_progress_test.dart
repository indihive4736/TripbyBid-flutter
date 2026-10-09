import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/features/trips/domain/entities/bid.dart';
import 'package:tripbybid/features/trips/domain/entities/booking.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_detail.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_progress.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_stage.dart';

import '../trips_fakes.dart';

void main() {
  group('TripProgress', () {
    List<TripStepStatus> statuses(TripStage stage) => [
      for (final step in TripStep.values) TripProgress.of(stage).statusOf(step),
    ];
    const done = TripStepStatus.done;
    const now = TripStepStatus.current;
    const next = TripStepStatus.upcoming;

    test('bidding: posted, waiting on bids', () {
      for (final stage in [TripStage.awaitingBids, TripStage.bidsIn]) {
        expect(statuses(stage), [done, now, next, next, next]);
      }
    });

    test('payment due: accepted, waiting on payment', () {
      expect(statuses(TripStage.paymentDue), [done, done, done, now, next]);
    });

    test('paid: waiting on the ticket', () {
      for (final stage in [
        TripStage.awaitingConfirmation,
        TripStage.awaitingTicket,
        TripStage.needsAttention,
      ]) {
        expect(statuses(stage), [done, done, done, done, now]);
      }
    });

    test('ticket ready and completed: everything done', () {
      for (final stage in [TripStage.ticketReady, TripStage.completed]) {
        expect(statuses(stage), List.filled(5, done));
        expect(TripProgress.of(stage).current, isNull);
      }
    });

    test('cancelled and expired are muted', () {
      for (final stage in [TripStage.cancelled, TripStage.expired]) {
        expect(statuses(stage), [TripStepStatus.muted, next, next, next, next]);
      }
    });
  });

  group('TripTimeline', () {
    final bid1 = TripFixtures.bid();
    final bid2 = TripFixtures.bid(id: 'bid-2', price: 18450, agentName: 'Sky');

    List<TimelineKind> kinds(TripDetail d) => [
      for (final e in TripTimeline.of(d)) e.kind,
    ];

    test('awaiting bids: posted, then bids arrive up next', () {
      final events = TripTimeline.of(
        TripDetail(request: TripFixtures.request(), activeBids: const []),
      );
      expect(events.map((e) => e.kind), [
        TimelineKind.posted,
        TimelineKind.bidsArrive,
      ]);
      expect(events.first.at, DateTime(2026, 10, 1, 10, 12));
      expect(events.first.amount, 20000);
      expect(events.last.upNext, isTrue);
    });

    test('bids in: count, best offer and first arrival', () {
      final detail = TripDetail(
        request: TripFixtures.request(bidsCount: 2, bids: [bid1, bid2]),
        activeBids: [bid2, bid1],
      );
      final events = TripTimeline.of(detail);
      expect(kinds(detail), [
        TimelineKind.posted,
        TimelineKind.bidsReceived,
        TimelineKind.acceptBid,
      ]);
      final bids = events[1];
      expect(bids.count, 2);
      expect(bids.amount, 17999);
      expect(bids.agentName, 'AirTrek India');
      expect(bids.at, DateTime(2026, 10, 1, 10, 19));
    });

    test('payment due: accepted with the hold, pay up next', () {
      final due = DateTime(2026, 10, 2, 11);
      final accepted = Bid(
        id: 'bid-1',
        requestId: 'r',
        agentId: 'a',
        price: 17999,
        status: BidStatus.accepted,
        agentName: 'AirTrek India',
        createdAt: DateTime(2026, 10, 1, 10, 19),
        acceptedAt: DateTime(2026, 10, 1, 11, 2),
        paymentDueAt: due,
      );
      final detail = TripDetail(
        request: TripFixtures.request(
          status: 'payment_pending',
          bidsCount: 2,
          bids: [accepted, bid2],
        ),
        activeBids: const [],
      );
      final events = TripTimeline.of(detail);
      expect(kinds(detail), [
        TimelineKind.posted,
        TimelineKind.bidsReceived,
        TimelineKind.accepted,
        TimelineKind.payToConfirm,
      ]);
      expect(events[2].at, DateTime(2026, 10, 1, 11, 2));
      expect(events[2].until, due);
      expect(events[3].until, due);
    });

    test('ticket ready: payment and ticket from the booking', () {
      final booking = Booking(
        id: 'booking-1',
        requestId: 'r',
        status: 'ticket_uploaded',
        price: 17999,
        createdAt: DateTime(2026, 10, 1, 11, 5),
        paymentDate: DateTime(2026, 10, 1, 11, 4),
        referenceNumber: 'TBB-X7K2',
        documents: [
          TripDocument(
            id: 'd1',
            type: 'ticket',
            fileName: 'eticket.pdf',
            status: 'pending',
            uploadedAt: DateTime(2026, 10, 1, 11, 40),
          ),
        ],
      );
      final detail = TripDetail(
        request: TripFixtures.request(
          status: 'ticket_uploaded',
          bidsCount: 1,
          bids: [TripFixtures.bid(status: BidStatus.selected)],
          booking: booking,
        ),
        activeBids: const [],
        booking: booking,
      );
      final events = TripTimeline.of(detail);
      expect(kinds(detail), [
        TimelineKind.posted,
        TimelineKind.bidsReceived,
        TimelineKind.accepted,
        TimelineKind.paid,
        TimelineKind.ticketIssued,
        TimelineKind.checkTicket,
      ]);
      expect(events[2].until, isNull, reason: 'paid: no hold any more');
      expect(events[3].at, DateTime(2026, 10, 1, 11, 4));
      expect(events[3].note, 'TBB-X7K2');
      expect(events[4].at, DateTime(2026, 10, 1, 11, 40));
      expect(events[4].note, 'eticket.pdf');
    });

    test('completed ends with the completion, nothing up next', () {
      final booking = Booking(
        id: 'booking-1',
        requestId: 'r',
        status: 'completed',
        price: 17999,
        createdAt: DateTime(2026, 10, 1, 11, 5),
        completedAt: DateTime(2026, 11, 12, 6, 10),
      );
      final detail = TripDetail(
        request: TripFixtures.request(
          status: 'completed',
          bidsCount: 1,
          bids: [TripFixtures.bid(status: BidStatus.selected)],
          booking: booking,
        ),
        activeBids: const [],
        booking: booking,
      );
      final events = TripTimeline.of(detail);
      expect(events.last.kind, TimelineKind.completed);
      expect(events.last.at, DateTime(2026, 11, 12, 6, 10));
      expect(events.any((e) => e.upNext), isFalse);
    });

    test('cancelled before payment: nothing charged', () {
      final detail = TripDetail(
        request: TripFixtures.request(status: 'cancelled'),
        activeBids: const [],
      );
      final events = TripTimeline.of(detail);
      expect(kinds(detail), [TimelineKind.posted, TimelineKind.cancelled]);
      expect(events.last.amount, isNull);
    });

    test('cancelled booking keeps the paid amount and reason', () {
      final booking = Booking(
        id: 'booking-1',
        requestId: 'r',
        status: 'cancelled',
        price: 17999,
        createdAt: DateTime(2026, 10, 1, 11, 5),
        cancelledAt: DateTime(2026, 10, 3, 9),
        cancellationReason: 'Plans changed',
      );
      final detail = TripDetail(
        request: TripFixtures.request(
          status: 'cancelled',
          bidsCount: 1,
          bids: [TripFixtures.bid(status: BidStatus.selected)],
          booking: booking,
        ),
        activeBids: const [],
        booking: booking,
      );
      final cancelled = TripTimeline.of(detail).last;
      expect(cancelled.kind, TimelineKind.cancelled);
      expect(cancelled.amount, 17999);
      expect(cancelled.at, DateTime(2026, 10, 3, 9));
      expect(cancelled.note, 'Plans changed');
    });
  });
}
