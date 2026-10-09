/// Where a trip is in its life, derived from the backend status.
///
/// The backend reports one `status` per request: the request's own state
/// (`pending`, `bidding`, `payment_pending`, `expired`, `cancelled`) until it
/// is booked, then the booking's state (`confirmed`, `ticket_uploaded`, …).
enum TripStage {
  /// Posted; no bids yet.
  awaitingBids,

  /// Bids are in; the traveler should compare and accept one.
  bidsIn,

  /// A bid is accepted and its fare is held until payment.
  paymentDue,

  /// Paid package booking waiting for the agent to confirm (24 h).
  awaitingConfirmation,

  /// Paid and booked; the agent is issuing the ticket.
  awaitingTicket,

  /// The agent uploaded the ticket; the traveler should check it.
  ticketReady,

  /// The traveler asked for a correction or raised a support ticket.
  needsAttention,

  completed,
  cancelled,
  expired;

  static TripStage of(String status, {required int bidsCount}) =>
      switch (status) {
        'pending' => awaitingBids,
        'bidding' => bidsCount > 0 ? bidsIn : awaitingBids,
        'payment_pending' => paymentDue,
        'awaiting_agent' => awaitingConfirmation,
        'confirmed' || 'in_progress' || 'awaiting_ticket' => awaitingTicket,
        'ticket_uploaded' || 'verification' => ticketReady,
        'needs_correction' || 'support_ticket_raised' => needsAttention,
        'completed' => completed,
        'expired' => expired,
        _ => cancelled,
      };

  /// Still in progress (shown under "Active").
  bool get isActive => !isClosed;

  bool get isClosed =>
      this == completed || this == cancelled || this == expired;

  /// A booking exists (the traveler has paid).
  bool get isBooked => switch (this) {
    awaitingConfirmation ||
    awaitingTicket ||
    ticketReady ||
    needsAttention ||
    completed => true,
    _ => false,
  };

  /// Still before payment: bids can be compared, accepted or released.
  bool get isBidding => this == awaitingBids || this == bidsIn;

  /// The traveler has something to do now.
  bool get needsAction =>
      this == bidsIn || this == paymentDue || this == ticketReady;
}
