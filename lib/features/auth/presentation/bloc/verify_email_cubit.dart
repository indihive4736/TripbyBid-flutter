import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/sign_up_usecases.dart';

enum VerifyStatus { entering, verifying, success, failure }

enum ResendStatus { idle, sending, sent, failed }

final class VerifyEmailState extends Equatable {
  const VerifyEmailState({
    this.email = '',
    this.code = '',
    this.status = VerifyStatus.entering,
    this.user,
    this.errorMessage,
    this.resendIn = 0,
    this.resendStatus = ResendStatus.idle,
    this.resendError,
  });

  static const codeLength = 6;

  final String email;

  /// Digits entered so far (0–6).
  final String code;
  final VerifyStatus status;

  /// Set when [status] is [VerifyStatus.success].
  final User? user;

  /// Set when [status] is [VerifyStatus.failure].
  final String? errorMessage;

  /// Seconds until a new code may be requested.
  final int resendIn;
  final ResendStatus resendStatus;

  /// Set when [resendStatus] is [ResendStatus.failed].
  final String? resendError;

  bool get isComplete => code.length == codeLength;

  int get digitsLeft => codeLength - code.length;

  bool get canResend =>
      resendIn == 0 &&
      resendStatus != ResendStatus.sending &&
      status != VerifyStatus.verifying &&
      status != VerifyStatus.success;

  bool get acceptsInput =>
      status != VerifyStatus.verifying && status != VerifyStatus.success;

  VerifyEmailState copyWith({
    String? email,
    String? code,
    VerifyStatus? status,
    User? user,
    String? errorMessage,
    int? resendIn,
    ResendStatus? resendStatus,
    String? resendError,
  }) => VerifyEmailState(
    email: email ?? this.email,
    code: code ?? this.code,
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: errorMessage,
    resendIn: resendIn ?? this.resendIn,
    resendStatus: resendStatus ?? this.resendStatus,
    resendError: resendError,
  );

  @override
  List<Object?> get props => [
    email,
    code,
    status,
    user,
    errorMessage,
    resendIn,
    resendStatus,
    resendError,
  ];
}

/// The 6-digit email code: keypad entry, auto-submit when complete, and a
/// resend countdown.
class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit({
    required VerifyEmailUseCase verifyEmail,
    required ResendCodeUseCase resendCode,
    this.resendCooldown = 30,
    this.tick = const Duration(seconds: 1),
  }) : _verifyEmail = verifyEmail,
       _resendCode = resendCode,
       super(const VerifyEmailState());

  final VerifyEmailUseCase _verifyEmail;
  final ResendCodeUseCase _resendCode;

  /// Seconds to wait before a code can be requested again.
  final int resendCooldown;

  /// One countdown step (a second; shorter in tests).
  final Duration tick;

  Timer? _timer;

  /// Begins with a code just sent to [email]: starts the resend countdown.
  void start(String email) {
    emit(state.copyWith(email: email));
    _startCountdown();
  }

  void digit(String value) {
    if (!state.acceptsInput || !RegExp(r'^\d$').hasMatch(value)) return;
    // After a rejected code the next digit starts a fresh one.
    final base = state.status == VerifyStatus.failure ? '' : state.code;
    if (base.length >= VerifyEmailState.codeLength) return;
    _setCode(base + value);
  }

  void backspace() {
    if (!state.acceptsInput || state.code.isEmpty) return;
    emit(
      state.copyWith(
        code: state.code.substring(0, state.code.length - 1),
        status: VerifyStatus.entering,
      ),
    );
  }

  /// Pasted or typed text: keeps its digits, up to six.
  void paste(String text) {
    if (!state.acceptsInput) return;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    _setCode(
      digits.length > VerifyEmailState.codeLength
          ? digits.substring(0, VerifyEmailState.codeLength)
          : digits,
    );
  }

  void _setCode(String code) {
    emit(state.copyWith(code: code, status: VerifyStatus.entering));
    if (state.isComplete) unawaited(_verify());
  }

  Future<void> _verify() async {
    emit(state.copyWith(status: VerifyStatus.verifying));
    final result = await _verifyEmail(
      VerifyEmailParams(email: state.email, code: state.code),
    );
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        status: VerifyStatus.success,
        user: value,
      ),
      Err(:final failure) => state.copyWith(
        status: VerifyStatus.failure,
        errorMessage: failure.message,
      ),
    });
    if (state.status == VerifyStatus.success) _timer?.cancel();
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    emit(state.copyWith(resendStatus: ResendStatus.sending));
    final result = await _resendCode(state.email);
    if (isClosed) return;
    switch (result) {
      case Ok():
        emit(
          state.copyWith(
            code: '',
            status: VerifyStatus.entering,
            resendStatus: ResendStatus.sent,
          ),
        );
        _startCountdown();
      case Err(:final failure):
        emit(
          state.copyWith(
            status: state.status,
            errorMessage: state.errorMessage,
            resendStatus: ResendStatus.failed,
            resendError: failure.message,
          ),
        );
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    emit(
      state.copyWith(
        resendIn: resendCooldown,
        errorMessage: state.errorMessage,
        resendError: state.resendError,
      ),
    );
    _timer = Timer.periodic(tick, (timer) {
      final left = state.resendIn - 1;
      emit(
        state.copyWith(
          resendIn: left < 0 ? 0 : left,
          errorMessage: state.errorMessage,
          resendError: state.resendError,
        ),
      );
      if (left <= 0) timer.cancel();
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
