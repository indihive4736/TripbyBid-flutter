import '../../../../core/error/exceptions.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_remote_data_source.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  const PaymentsRepositoryImpl(this._remote);

  final PaymentsRemoteDataSource _remote;

  @override
  Future<Result<PaymentSummary>> getSummary(String bidId) =>
      guard(() => _remote.getSummary(bidId));

  @override
  Future<Result<CheckoutSession>> startCheckout(String bidId) =>
      guard(() => _remote.initiate(bidId));

  @override
  Future<Result<String>> confirmAndBook({
    required String paymentId,
    required String bidId,
  }) => guard(() async {
    final status = await _remote.verify(paymentId);
    if (status != 'completed') {
      throw ServerException(
        status == 'pending'
            ? 'We have not received your payment yet. If money was '
                  'debited, it will be confirmed shortly — check My trips.'
            : 'The payment did not go through ($status). '
                  'You have not been charged.',
      );
    }
    return _remote.selectBid(bidId: bidId, paymentId: paymentId);
  });

  @override
  Future<Result<List<PaymentRecord>>> getHistory() => guard(_remote.getHistory);
}
