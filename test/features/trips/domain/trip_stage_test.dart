import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_stage.dart';

void main() {
  TripStage of(String status, [int bids = 0]) =>
      TripStage.of(status, bidsCount: bids);

  test('maps request and booking statuses to stages', () {
    expect(of('bidding'), TripStage.awaitingBids);
    expect(of('pending'), TripStage.awaitingBids);
    expect(of('bidding', 3), TripStage.bidsIn);
    expect(of('payment_pending', 3), TripStage.paymentDue);
    expect(of('awaiting_agent'), TripStage.awaitingConfirmation);
    for (final s in ['confirmed', 'in_progress', 'awaiting_ticket']) {
      expect(of(s), TripStage.awaitingTicket, reason: s);
    }
    expect(of('ticket_uploaded'), TripStage.ticketReady);
    expect(of('verification'), TripStage.ticketReady);
    expect(of('needs_correction'), TripStage.needsAttention);
    expect(of('support_ticket_raised'), TripStage.needsAttention);
    expect(of('completed'), TripStage.completed);
    expect(of('expired'), TripStage.expired);
    expect(of('cancelled'), TripStage.cancelled);
    expect(of('something_new'), TripStage.cancelled);
  });

  test('groups stages', () {
    expect(TripStage.bidsIn.isBidding, isTrue);
    expect(TripStage.paymentDue.isBooked, isFalse);
    expect(TripStage.awaitingTicket.isBooked, isTrue);
    expect(TripStage.completed.isClosed, isTrue);
    expect(TripStage.ticketReady.needsAction, isTrue);
    expect(TripStage.awaitingBids.needsAction, isFalse);
  });
}
