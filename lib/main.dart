import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'core/network/secure_session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  const secureStorage = FlutterSecureStorage();
  final supabase = await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(secureStorage),
    ),
  );
  configureDependencies(
    supabase: supabase.client,
    prefs: await SharedPreferences.getInstance(),
    secureStorage: secureStorage,
  );
  runApp(const TripByBidApp());
}

/// Shown when the app was built without `--dart-define-from-file`.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Missing configuration.\n\nRun with\n'
            '--dart-define-from-file=env/dev.json\n(see env/example.json).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
