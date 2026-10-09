/// Build-time configuration, set with `--dart-define`.
abstract final class AppConfig {
  /// Base URL of the NestJS API, including the `/api` prefix.
  ///
  /// The default suits the iOS simulator. On the Android emulator use
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:3001/api`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api',
  );
}
