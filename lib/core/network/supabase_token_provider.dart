import 'package:supabase_flutter/supabase_flutter.dart';

import 'access_token_provider.dart';

/// Bearer tokens from the Supabase Auth session. The backend's AuthGuard
/// accepts Supabase access tokens (the same tokens the web client sends).
///
/// supabase_flutter refreshes the session in the background; this class only
/// forces a refresh after the API rejects a token, and refreshes are
/// single-flight so concurrent 401s share one refresh call.
class SupabaseTokenProvider implements AccessTokenProvider {
  SupabaseTokenProvider(this._auth);

  final GoTrueClient _auth;
  Future<String?>? _refreshInFlight;

  @override
  Future<String?> accessToken() async {
    final session = _auth.currentSession;
    if (session == null) return null;
    if (session.isExpired) return _refresh();
    return session.accessToken;
  }

  @override
  Future<String?> refreshAfterRejection(String rejected) async {
    final current = _auth.currentSession;
    if (current == null) return null;
    // Another request already refreshed while this one was in flight.
    if (current.accessToken != rejected) return current.accessToken;
    final fresh = await _refresh();
    if (fresh == null) {
      // The session is unrecoverable: signing out notifies AuthBloc through
      // the auth state stream, which routes back to the login screen.
      await _auth.signOut(scope: SignOutScope.local);
    }
    return fresh;
  }

  Future<String?> _refresh() => _refreshInFlight ??= _doRefresh().whenComplete(
    () => _refreshInFlight = null,
  );

  Future<String?> _doRefresh() async {
    try {
      final response = await _auth.refreshSession();
      return response.session?.accessToken;
    } on AuthException {
      return null;
    }
  }
}
