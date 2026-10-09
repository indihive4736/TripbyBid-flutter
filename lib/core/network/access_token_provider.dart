/// Supplies the bearer token for authenticated API calls.
///
/// Kept abstract so the API client does not depend on how sessions are issued
/// (Supabase today; backend-issued JWTs once the backend finishes moving auth
/// off Supabase).
abstract interface class AccessTokenProvider {
  /// The current access token, refreshed first if it is about to expire, or
  /// `null` when signed out.
  Future<String?> accessToken();

  /// Called after the API rejected [rejected] with a 401. Returns a fresh
  /// token, or `null` when the session cannot be recovered (the provider then
  /// ends the session, which signs the user out app-wide).
  Future<String?> refreshAfterRejection(String rejected);
}
