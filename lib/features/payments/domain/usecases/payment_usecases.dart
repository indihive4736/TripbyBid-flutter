import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/checkout.dart';
import '../repositories/payments_repository.dart';

/// [params] is the bid id.
class GetPaymentSummaryUseCase implements UseCase<PaymentSummary, String> {
  const GetPaymentSummaryUseCase(this._repository);

  final PaymentsRepository _repository;

  @override
  Future<Result<PaymentSummary>> call(String params) =>
      _repository.getSummary(params);
}

class GetPaymentHistoryUseCase
    implements UseCase<List<PaymentRecord>, NoParams> {
  const GetPaymentHistoryUseCase(this._repository);

  final PaymentsRepository _repository;

  @override
  Future<Result<List<PaymentRecord>>> call(NoParams params) =>
      _repository.getHistory();
}

/// How paying for a bid ended.
sealed class PaymentOutcome {
  const PaymentOutcome();
}

/// Paid and booked.
final class PaymentBooked extends PaymentOutcome {
  const PaymentBooked(this.bookingId);

  final String bookingId;
}

/// The traveler closed the checkout without paying.
final class PaymentAbandoned extends PaymentOutcome {
  const PaymentAbandoned();
}

/// Pays for a bid end to end: create the order, run the gateway checkout on
/// the device, then have the backend verify the payment and book the bid.
/// [params] is the bid id.
class PayForBidUseCase implements UseCase<PaymentOutcome, String> {
  const PayForBidUseCase(this._repository, this._gateway);

  final PaymentsRepository _repository;
  final PaymentGateway _gateway;

  @override
  Future<Result<PaymentOutcome>> call(String params) async {
    final checkout = await _repository.startCheckout(params);
    final CheckoutSession session;
    switch (checkout) {
      case Ok(:final value):
        session = value;
      case Err(:final failure):
        return Err(failure);
    }

    final outcome = await _gateway.pay(session);
    if (outcome == GatewayOutcome.cancelled) {
      return const Ok(PaymentAbandoned());
    }

    // Even when the device reports a failure, ask the backend: the gateway
    // may have captured the money anyway, and booking it now avoids a second
    // charge on retry.
    final booked = await _repository.confirmAndBook(
      paymentId: session.paymentId,
      bidId: params,
    );
    return switch (booked) {
      Ok(:final value) => Ok(PaymentBooked(value)),
      Err() when outcome == GatewayOutcome.failed => const Err(
        ServerFailure(
          'The payment did not go through. You have not been charged.',
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
