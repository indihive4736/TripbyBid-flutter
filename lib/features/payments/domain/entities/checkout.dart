/// Price breakdown shown before paying for a bid.
final class PaymentSummary {
  const PaymentSummary({
    required this.bidId,
    required this.total,
    required this.baseFare,
    required this.serviceCharge,
    this.agentName,
    this.paymentDueAt,
  });

  final String bidId;

  /// Amount charged (the bid price), INR.
  final double total;

  /// What the agent receives.
  final double baseFare;

  /// TripByBid's non-refundable platform fee, included in [total].
  final double serviceCharge;
  final String? agentName;
  final DateTime? paymentDueAt;
}

/// A payment order created on the backend, ready for the gateway.
final class CheckoutSession {
  const CheckoutSession({
    required this.paymentId,
    required this.orderId,
    required this.sessionId,
    required this.amount,
  });

  final String paymentId;

  /// Gateway order id (`BID_<uuid>`).
  final String orderId;

  /// Cashfree `payment_session_id`.
  final String sessionId;
  final double amount;

  @override
  bool operator ==(Object other) =>
      other is CheckoutSession &&
      other.paymentId == paymentId &&
      other.orderId == orderId &&
      other.sessionId == sessionId &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(paymentId, orderId, sessionId, amount);
}

/// How the gateway checkout ended on the device. Success here is not proof
/// of payment — the backend verifies with the gateway afterwards.
enum GatewayOutcome { completed, cancelled, failed }

/// A row in the traveler's payment history.
final class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.tripTitle,
    this.agentName,
    this.receiptNumber,
    this.completedAt,
  });

  final String id;
  final double amount;

  /// `pending`, `completed`, `failed`, `expired`, `refunded`, `cancelled`.
  final String status;
  final DateTime createdAt;
  final String? tripTitle;
  final String? agentName;
  final String? receiptNumber;
  final DateTime? completedAt;
}
