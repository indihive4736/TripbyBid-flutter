import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/indian_phone.dart';
import '../../domain/entities/password_strength.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_up_usecases.dart';

enum SignupStatus {
  editing,
  submitting,

  /// A 6-digit code was emailed: go to code entry for [SignupState.email].
  codeSent,

  /// The account is ready and signed in: [SignupState.user] is set.
  signedIn,

  /// The account was created but the session could not be loaded: log in.
  loginRequired,
  failure,
}

final class SignupState extends Equatable {
  const SignupState({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.acceptedTerms = false,
    this.status = SignupStatus.editing,
    this.user,
    this.errorMessage,
  });

  final String name;
  final String email;

  /// The 10 local digits (the +91 prefix is shown by the field).
  final String phone;
  final String password;
  final bool acceptedTerms;
  final SignupStatus status;
  final User? user;
  final String? errorMessage;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  PasswordStrength get strength => PasswordStrength.of(password);

  bool get emailLooksValid => _emailPattern.hasMatch(email.trim());

  bool get phoneLooksValid => IndianPhone.normalize(phone) != null;

  /// Mirrors [SignUpUseCase]'s rules so the button only enables when the
  /// form would pass; the use case stays the authority.
  bool get isValid {
    final trimmedName = name.trim();
    return trimmedName.length >= 2 &&
        trimmedName.length <= 60 &&
        emailLooksValid &&
        phoneLooksValid &&
        strength.isAcceptable &&
        password.length <= 72 &&
        acceptedTerms;
  }

  bool get canSubmit => isValid && status != SignupStatus.submitting;

  SignupState copyWith({
    String? name,
    String? email,
    String? phone,
    String? password,
    bool? acceptedTerms,
    SignupStatus? status,
    User? user,
    String? errorMessage,
  }) => SignupState(
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    password: password ?? this.password,
    acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    password,
    acceptedTerms,
    status,
    user,
    errorMessage,
  ];
}

/// The signup form: field values, live validity and submission.
class SignupCubit extends Cubit<SignupState> {
  SignupCubit({
    required SignUpUseCase signUp,
    required GetCurrentUserUseCase getCurrentUser,
  }) : _signUp = signUp,
       _getCurrentUser = getCurrentUser,
       super(const SignupState());

  final SignUpUseCase _signUp;
  final GetCurrentUserUseCase _getCurrentUser;

  void nameChanged(String value) => _edit(state.copyWith(name: value));

  void emailChanged(String value) => _edit(state.copyWith(email: value));

  void phoneChanged(String value) => _edit(state.copyWith(phone: value));

  void passwordChanged(String value) => _edit(state.copyWith(password: value));

  void termsToggled() =>
      _edit(state.copyWith(acceptedTerms: !state.acceptedTerms));

  void _edit(SignupState next) {
    if (state.status == SignupStatus.submitting) return;
    emit(next.copyWith(status: SignupStatus.editing));
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(status: SignupStatus.submitting));
    final result = await _signUp(
      SignUpParams(
        name: state.name,
        email: state.email,
        phone: state.phone,
        password: state.password,
        acceptedTerms: state.acceptedTerms,
      ),
    );
    switch (result) {
      case Ok(value: true):
        emit(
          state.copyWith(
            email: state.email.trim().toLowerCase(),
            status: SignupStatus.codeSent,
          ),
        );
      case Ok(value: false):
        // No code needed: the account is already signed in.
        final current = await _getCurrentUser(const NoParams());
        emit(switch (current) {
          Ok(value: final User user) => state.copyWith(
            status: SignupStatus.signedIn,
            user: user,
          ),
          Ok() || Err() => state.copyWith(status: SignupStatus.loginRequired),
        });
      case Err(:final failure):
        emit(
          state.copyWith(
            status: SignupStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
