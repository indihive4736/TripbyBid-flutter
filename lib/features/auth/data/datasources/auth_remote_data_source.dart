import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/parse.dart';
import '../models/user_model.dart';

/// Sign-up, email verification and sign-in run on Supabase Auth, exactly as
/// on the web client; the profile comes from the NestJS API (`/users/me`),
/// which accepts the Supabase access token.
///
/// Throws `AppException`s.
abstract interface class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});

  /// Returns true when a verification code was emailed.
  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<UserModel> verifyEmail({required String email, required String code});
  Future<void> resendCode(String email);
  bool get hasSession;

  /// The profile of the signed-in user, or null without a profile row.
  Future<UserModel?> getProfile();
  Future<void> signOut();
  Stream<void> get sessionEnded;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required supa.GoTrueClient auth,
    required ApiClient api,
  }) : _auth = auth,
       _api = api;

  final supa.GoTrueClient _auth;
  final ApiClient _api;

  /// Set while [signOut] runs so a user-initiated logout is not reported as
  /// an unexpected session end.
  bool _signingOut = false;

  @override
  bool get hasSession => _auth.currentSession != null;

  @override
  Stream<void> get sessionEnded => _auth.onAuthStateChange
      .where(
        (state) =>
            state.event == supa.AuthChangeEvent.signedOut && !_signingOut,
      )
      .map((_) {});

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _authCall(
      () => _auth.signInWithPassword(email: email, password: password),
    );
    return _travelerProfile();
  }

  @override
  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _authCall(
      () => _auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': 'user', 'phone': phone},
      ),
    );
    // Supabase answers an existing, confirmed email with a user that has no
    // identities instead of an error.
    final identities = response.user?.identities;
    if (identities != null && identities.isEmpty) {
      throw const ServerException(
        'This email is already registered. Log in instead.',
        statusCode: 409,
      );
    }
    return response.session == null;
  }

  @override
  Future<UserModel> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _authCall(
      () =>
          _auth.verifyOTP(type: supa.OtpType.signup, email: email, token: code),
    );
    // The signup trigger may not copy the phone into the profile; send it
    // explicitly like the web client does.
    final phone = response.user?.userMetadata?['phone'];
    if (phone is String && phone.isNotEmpty) {
      try {
        await _api.patch('/users/me', body: {'phone': phone});
      } on AppException {
        // Not fatal: the traveler can add it from their profile.
      }
    }
    return _travelerProfile();
  }

  @override
  Future<void> resendCode(String email) =>
      _authCall(() => _auth.resend(type: supa.OtpType.signup, email: email));

  @override
  Future<UserModel?> getProfile() async {
    final json = await _api.get('/users/me');
    if (json is! Map<String, Object?>) return null;
    return parseResponse(() => UserModel.fromJson(json));
  }

  @override
  Future<void> signOut() async {
    _signingOut = true;
    try {
      await _auth.signOut();
    } on supa.AuthException {
      // The local session is cleared even when the server call fails.
    } finally {
      _signingOut = false;
    }
  }

  /// Loads the profile and refuses non-traveler accounts: this app is for
  /// travelers only; agents use the web dashboard.
  Future<UserModel> _travelerProfile() async {
    final UserModel? user;
    try {
      user = await getProfile();
    } on AppException {
      await signOut();
      rethrow;
    }
    if (user == null) {
      await signOut();
      throw const ServerException('Your profile is not ready yet. Try again.');
    }
    if (user.role != 'user') {
      await signOut();
      throw const UnauthorizedException(
        'This app is for travelers. Agents can sign in on the TripByBid '
        'web dashboard.',
      );
    }
    return user;
  }

  /// Maps Supabase Auth errors to the app's exceptions.
  static Future<T> _authCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on supa.AuthRetryableFetchException {
      throw const NetworkException();
    } on supa.AuthException catch (e) {
      throw switch ((e.code, e.message.toLowerCase())) {
        ('email_not_confirmed', _) ||
        (_, 'email not confirmed') => const EmailNotVerifiedException(),
        ('invalid_credentials', _) || (_, 'invalid login credentials') =>
          const UnauthorizedException('Email or password is incorrect.'),
        ('otp_expired', _) => const ServerException(
          'That code has expired or is wrong. Request a new one.',
        ),
        ('user_already_exists', _) => const ServerException(
          'This email is already registered. Log in instead.',
          statusCode: 409,
        ),
        ('over_email_send_rate_limit', _) ||
        ('over_request_rate_limit', _) => const ServerException(
          'Too many attempts. Wait a minute and try again.',
          statusCode: 429,
        ),
        _ => ServerException(e.message),
      };
    }
  }
}
