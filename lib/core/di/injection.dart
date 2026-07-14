import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aina/core/network/dio_client.dart';
import 'package:aina/core/network/network_info.dart';
import 'package:aina/core/services/location_service.dart';
import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/core/storage/secure_storage_service.dart';
import 'package:aina/core/storage/shared_prefs_service.dart';

/// Root DI graph, built with plain Riverpod `Provider`s (no code
/// generation) so the object graph is fully readable without running
/// `build_runner` — every feature module's own providers (Phase 4+)
/// depend on these rather than instantiating services directly.

// ---------------------------------------------------------------
// SharedPreferences must be resolved asynchronously before runApp,
// so this provider is overridden in main_*.dart with the awaited
// instance. It intentionally throws if read before that override is
// applied — a clear signal of an ordering bug rather than a silent null.
// ---------------------------------------------------------------
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main_*.dart after '
    'awaiting SharedPreferences.getInstance()',
  );
});

final sharedPrefsServiceProvider = Provider<SharedPrefsService>((ref) {
  return SharedPrefsService(ref.watch(sharedPreferencesProvider));
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.watch(secureStorageProvider));
});

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(ref.watch(connectivityProvider));
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

final dioProvider = Provider<Dio>((ref) {
  final client = DioClient(
    ref.watch(supabaseClientProvider),
    ref.watch(networkInfoProvider),
  );
  return client.build();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});
