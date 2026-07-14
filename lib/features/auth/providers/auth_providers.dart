import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aina/features/auth/data/repositories/auth_repository.dart';
import 'package:aina/core/services/supabase_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

/// Exposes the current auth state as a stream, so widgets can react to
/// sign-in / sign-out / password-recovery events. GoRouter's refresh
/// listenable (Phase 4) also watches this to redirect between
/// `/login` and `/home` automatically.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.onAuthStateChange;
});

/// True from the moment the app is opened via the password-reset deep
/// link until [ResetPasswordScreen] clears it after a successful
/// `updatePassword` call. [RouteGuards] reads this to force navigation
/// to `/reset-password` regardless of where the user was headed.
final passwordRecoveryProvider = StateProvider<bool>((ref) => false);
