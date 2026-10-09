/// The backend session: a short-lived access token (15 min) and a rotating
/// refresh token.
final class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Parses the `session` object returned by `/auth/login` and `/auth/refresh`,
  /// where `expires_at` is in Unix seconds.
  factory AuthTokens.fromSessionJson(Map<String, Object?> json) {
    if (json case {
      'access_token': final String accessToken,
      'refresh_token': final String refreshToken,
      'expires_at': final num expiresAt,
    }) {
      return AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          (expiresAt * 1000).round(),
          isUtc: true,
        ),
      );
    }
    throw const FormatException('Invalid session payload');
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Whether the access token expires before [now] + [margin].
  bool expiresWithin(Duration margin, DateTime now) =>
      !expiresAt.isAfter(now.add(margin));

  Map<String, Object?> toSessionJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.millisecondsSinceEpoch / 1000,
  };

  @override
  bool operator ==(Object other) =>
      other is AuthTokens &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresAt);
}
