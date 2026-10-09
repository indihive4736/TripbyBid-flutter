import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/parse.dart';
import '../../domain/entities/checkout.dart';

/// Bid payments on the NestJS API. Throws `AppException`s.
abstract interface class PaymentsRemoteDataSource {
  Future<PaymentSummary> getSummary(String bidId);
  Future<CheckoutSession> initiate(String bidId);

  /// Asks the backend to check the order with the gateway; returns the
  /// payment status (`completed` once paid).
  Future<String> verify(String paymentId);

  /// Books the bid with a completed payment; returns the booking id.
  Future<String> selectBid({required String bidId, required String paymentId});
  Future<List<PaymentRecord>> getHistory();
}

class PaymentsRemoteDataSourceImpl implements PaymentsRemoteDataSource {
  const PaymentsRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  @override
  Future<PaymentSummary> getSummary(String bidId) async {
    final json = await _api.get('/bids/$bidId/payment-summary');
    return parseResponse(() {
      final root = JsonReader.of(json);
      final order =
          root.object('orderSummary') ??
          (throw const FormatException('Missing orderSummary'));
      return PaymentSummary(
        bidId: bidId,
        total: order.number('total'),
        baseFare: order.number('baseFare'),
        serviceCharge: order.number('serviceCharge'),
        agentName: root.object('agent')?.stringOrNull('name'),
        paymentDueAt: root.object('bid')?.dateOrNull('payment_due_at'),
      );
    });
  }

  @override
  Future<CheckoutSession> initiate(String bidId) async {
    final json = await _api.post(
      '/payments/initiate',
      body: {'bidId': bidId, 'currency': 'INR', 'paymentProvider': 'cashfree'},
    );
    return parseResponse(() {
      final payment = JsonReader.of(json);
      final gateway = payment.object('gatewayResponse');
      final sessionId = gateway?.stringOrNull('payment_session_id');
      if (sessionId == null) {
        throw const ServerException(
          'Could not start the payment. Please try again.',
        );
      }
      return CheckoutSession(
        paymentId: payment.string('id'),
        orderId:
            gateway?.stringOrNull('order_id') ??
            payment.stringOrNull('internal_order_id') ??
            'BID_${payment.string('id')}',
        sessionId: sessionId,
        amount: payment.number('amount'),
      );
    });
  }

  @override
  Future<String> verify(String paymentId) async {
    final json = await _api.post('/payments/verify/$paymentId');
    return parseResponse(() => JsonReader.of(json).string('status'));
  }

  @override
  Future<String> selectBid({
    required String bidId,
    required String paymentId,
  }) async {
    final json = await _api.patch(
      '/bids/$bidId/select',
      body: {'paymentId': paymentId},
    );
    return parseResponse(() {
      final root = JsonReader.of(json);
      return (root.object('booking') ?? root).string('id');
    });
  }

  @override
  Future<List<PaymentRecord>> getHistory() async {
    final json = await _api.get('/payments/user/me', query: {'limit': '50'});
    return parseResponse(
      () => [
        for (final p in JsonReader.of(json).objects('bidPayments'))
          PaymentRecord(
            id: p.string('id'),
            amount: p.number('amount'),
            status: p.stringOrNull('status') ?? 'pending',
            createdAt: p.date('created_at'),
            completedAt: p.dateOrNull('payment_completed_at'),
            receiptNumber: p.stringOrNull('receipt_number'),
            tripTitle: p.object('trip')?.stringOrNull('title'),
            agentName: p.object('bids')?.stringOrNull('agent_name'),
          ),
      ],
    );
  }
}
