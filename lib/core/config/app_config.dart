/// Build-time configuration, passed with
/// `--dart-define-from-file=env/dev.json` (see `env/example.json`).
abstract final class AppConfig {
  /// Base URL of the NestJS API, including the `/api` prefix.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api',
  );

  /// Supabase project — used for sign-up, email verification and sign-in,
  /// as on the web client.
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// `sandbox` or `production` Cashfree checkout.
  static const cashfreeEnv = String.fromEnvironment(
    'CASHFREE_ENV',
    defaultValue: 'sandbox',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
