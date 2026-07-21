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

  /// Launches Google's OAuth consent flow in the system browser, then
  /// redirects back into the app via the same deep link used for email
  /// confirmation/password reset (`AuthConstants.redirectUrl`) - already
  /// registered natively on both platforms, so no extra native config
  /// is needed for this to work.
  ///
  /// This returns as soon as the browser is launched, NOT once sign-in
  /// completes - the actual session arrives asynchronously via
  /// `SupabaseService.onAuthStateChange`, which RouteGuards already
  /// listens to for navigation. A first-time Google sign-in creates the
  /// account automatically; `handle_new_user_profile` still fires, just
  /// with no `role` in metadata (OAuth doesn't let us inject that ahead
  /// of time) - it defaults to 'customer', same as the DB column
  /// default. That's fine under the "one account, two hats" model:
  /// they can claim/register a salon and switch to Business view
  /// whenever they like, exactly like an email/password customer can.
  Future<void> signInWithGoogle() {
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AuthConstants.redirectUrl,
    );
  }

  /// Same as [signInWithGoogle], via GitHub instead.
  Future<void> signInWithGitHub() {
    return _auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: AuthConstants.redirectUrl,
    );
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

  /// Resends the signup confirmation email. Used by the login screen's
  /// "Resend confirmation email" fallback, offered generically after
  /// repeated failed attempts (not conditioned on whether the account
  /// is actually unconfirmed) so its mere presence doesn't leak
  /// anything about a specific email - see LoginScreen.
  Future<void> resendConfirmationEmail(String email) {
    return _auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: AuthConstants.redirectUrl,
    );
  }

  /// Call this from the "set new password" screen reached via the
  /// recovery deep link — the recovery session is already active at
  /// that point, so no old password is required.
  Future<UserResponse> updatePassword(String newPassword) {
    return _auth.updateUser(UserAttributes(password: newPassword));
  }
}