import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aina/core/config/env.dart';

/// Bootstraps the Supabase SDK once at app startup and exposes the
/// singleton client. Every feature repository reads tables/storage/auth
/// through `SupabaseService.client` rather than calling
/// `Supabase.instance.client` directly, so there is one seam to mock in
/// repository tests.
class SupabaseService {
  const SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.error,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static Session? get currentSession => client.auth.currentSession;

  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentSession != null;

  /// Emits on every auth state change (sign in, sign out, token refresh) —
  /// consumed by the router's refresh listenable in Phase 4.
  static Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;
}
