import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../payments/domain/entities/checkout.dart';
import '../../../payments/domain/usecases/payment_usecases.dart';

sealed class PaymentHistoryState extends Equatable {
  const PaymentHistoryState();

  @override
  List<Object?> get props => [];
}

final class PaymentHistoryLoading extends PaymentHistoryState {
  const PaymentHistoryLoading();
}

final class PaymentHistoryLoaded extends PaymentHistoryState {
  const PaymentHistoryLoaded(this.payments);

  final List<PaymentRecord> payments;

  @override
  List<Object?> get props => [payments];
}

final class PaymentHistoryError extends PaymentHistoryState {
  const PaymentHistoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class PaymentHistoryCubit extends Cubit<PaymentHistoryState> {
  PaymentHistoryCubit({required GetPaymentHistoryUseCase getHistory})
    : _getHistory = getHistory,
      super(const PaymentHistoryLoading());

  final GetPaymentHistoryUseCase _getHistory;

  Future<void> load() async {
    emit(const PaymentHistoryLoading());
    await refresh();
  }

  /// Reloads in place: a failed refresh keeps the list already shown.
  Future<void> refresh() async {
    final result = await _getHistory(const NoParams());
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(PaymentHistoryLoaded(value));
      case Err(:final failure):
        if (state is! PaymentHistoryLoaded) {
          emit(PaymentHistoryError(failure.message));
        }
    }
  }
}
