import '../../../../core/error/result.dart';
import '../entities/checkout.dart';

abstract interface class PaymentsRepository {
  Future<Result<PaymentSummary>> getSummary(String bidId);

  /// Creates a payment order for the bid's price.
  Future<Result<CheckoutSession>> startCheckout(String bidId);

  /// Asks the backend to confirm the payment with the gateway, then books the
  /// bid. Returns the booking id.
  Future<Result<String>> confirmAndBook({
    required String paymentId,
    required String bidId,
  });

  Future<Result<List<PaymentRecord>>> getHistory();
}

/// The on-device payment UI (Cashfree checkout).
abstract interface class PaymentGateway {
  Future<GatewayOutcome> pay(CheckoutSession session);
}
