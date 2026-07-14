import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aina/app.dart';
import 'package:aina/core/config/env.dart';
import 'package:aina/core/config/flavor_config.dart';
import 'package:aina/core/di/injection.dart';
import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/core/storage/hive_service.dart';
import 'package:aina/core/utils/logger.dart';

/// Shared startup sequence invoked by each `main_<flavor>.dart`. Keeping
/// this in one place means every flavor initializes services in the
/// exact same order — a common source of "works in dev, crashes in
/// prod" bugs is flavors quietly drifting apart in their main() bodies.
Future<void> bootstrap(Environment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlavorConfig.initialize(environment);
  Env.assertConfigured();

  await Future.wait([
    SupabaseService.initialize(),
    HiveService.initialize(),
  ]);

  final sharedPreferences = await SharedPreferences.getInstance();

  FlutterError.onError = (details) {
    AppLogger.error('FlutterError caught', details.exception, details.stack);
  };

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const AinaApp(),
    ),
  );
}
