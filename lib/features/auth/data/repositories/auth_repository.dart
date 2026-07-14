import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aina/core/constants/auth_constants.dart';
import 'package:aina/core/services/supabase_service.dart';

/// Thin wrapper around Supabase's GoTrue auth calls. Feature-level
/// providers (Riverpod) depend on this rather than calling
/// `SupabaseService.auth` directly, so the redirect URL and error
/// handling live in exactly one place.
class AuthRepository {
  const AuthRepository();

  GoTrueClient get _auth => SupabaseService.auth;

  /// Creates a new account. `fullName` and `role` are stored in
  /// `raw_user_meta_data` and picked up by the `handle_new_user_profile`
  /// DB trigger to seed `profiles`. `role` determines which part of the
  /// app the person lands in after signing in - see `RoleGate`.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
      emailRedirectTo: AuthConstants.redirectUrl,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  /// Sends a password-reset email containing a deep link back into the
  /// app. The recovery event arrives on `SupabaseService.onAuthStateChange`
  /// as `AuthChangeEvent.passwordRecovery` — the router should watch for
  /// that event and navigate to a "set new password" screen.
  Future<void> resetPasswordForEmail(String email) {
    return _auth.resetPasswordForEmail(
      email,
      redirectTo: AuthConstants.redirectUrl,
    );
  }

  /// Call this from the "set new password" screen reached via the
  /// recovery deep link — the recovery session is already active at
  /// that point, so no old password is required.
  Future<UserResponse> updatePassword(String newPassword) {
    return _auth.updateUser(UserAttributes(password: newPassword));
  }
}
