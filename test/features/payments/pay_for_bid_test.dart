import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/payments/domain/entities/checkout.dart';
import 'package:tripbybid/features/payments/domain/repositories/payments_repository.dart';
import 'package:tripbybid/features/payments/domain/usecases/payment_usecases.dart';

const _session = CheckoutSession(
  paymentId: 'pay-1',
  orderId: 'BID_pay-1',
  sessionId: 'session-1',
  amount: 17999,
);

class FakePaymentsRepository implements PaymentsRepository {
  Result<CheckoutSession> checkoutResult = const Ok(_session);
  Result<String> confirmResult = const Ok('booking-1');
  final calls = <String>[];

  @override
  Future<Result<PaymentSummary>> getSummary(String bidId) =>
      throw UnimplementedError();

  @override
  Future<Result<CheckoutSession>> startCheckout(String bidId) async {
    calls.add('startCheckout:$bidId');
    return checkoutResult;
  }

  @override
  Future<Result<String>> confirmAndBook({
    required String paymentId,
    required String bidId,
  }) async {
    calls.add('confirmAndBook:$paymentId:$bidId');
    return confirmResult;
  }

  @override
  Future<Result<List<PaymentRecord>>> getHistory() =>
      throw UnimplementedError();
}

class FakeGateway implements PaymentGateway {
  FakeGateway(this.outcome);

  final GatewayOutcome outcome;
  CheckoutSession? paid;

  @override
  Future<GatewayOutcome> pay(CheckoutSession session) async {
    paid = session;
    return outcome;
  }
}

void main() {
  late FakePaymentsRepository repository;

  setUp(() => repository = FakePaymentsRepository());

  test('creates the order, pays, then books with the payment', () async {
    final gateway = FakeGateway(GatewayOutcome.completed);

    final result = await PayForBidUseCase(repository, gateway)('bid-1');

    expect(gateway.paid, _session);
    expect(repository.calls, [
      'startCheckout:bid-1',
      'confirmAndBook:pay-1:bid-1',
    ]);
    expect(
      result,
      isA<Ok<PaymentOutcome>>().having(
        (r) => (r.value as PaymentBooked).bookingId,
        'bookingId',
        'booking-1',
      ),
    );
  });

  test('closing the checkout is not an error and books nothing', () async {
    final result = await PayForBidUseCase(
      repository,
      FakeGateway(GatewayOutcome.cancelled),
    )('bid-1');

    expect(result, isA<Ok<PaymentOutcome>>());
    expect((result as Ok<PaymentOutcome>).value, isA<PaymentAbandoned>());
    expect(repository.calls, ['startCheckout:bid-1']);
  });

  test('a device-side failure still asks the backend (money may be '
      'captured) and books if it was', () async {
    final result = await PayForBidUseCase(
      repository,
      FakeGateway(GatewayOutcome.failed),
    )('bid-1');

    expect(repository.calls.last, 'confirmAndBook:pay-1:bid-1');
    expect((result as Ok<PaymentOutcome>).value, isA<PaymentBooked>());
  });

  test('a real failure reports that nothing was charged', () async {
    repository.confirmResult = const Err(ServerFailure('pending'));

    final result = await PayForBidUseCase(
      repository,
      FakeGateway(GatewayOutcome.failed),
    )('bid-1');

    expect(
      result,
      const Err<Never>(
        ServerFailure(
          'The payment did not go through. You have not been charged.',
        ),
      ),
    );
  });

  test('stops when the order cannot be created', () async {
    repository.checkoutResult = const Err(
      ServerFailure('The payment deadline for this bid has passed'),
    );
    final gateway = FakeGateway(GatewayOutcome.completed);

    final result = await PayForBidUseCase(repository, gateway)('bid-1');

    expect(result, isA<Err<PaymentOutcome>>());
    expect(gateway.paid, isNull);
  });
}
