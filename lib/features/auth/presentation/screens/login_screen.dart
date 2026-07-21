import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/auth/providers/auth_providers.dart';

/// After this many consecutive failed attempts, a generic "resend
/// confirmation email" option appears - offered unconditionally
/// (not because we've detected the account is actually unconfirmed),
/// so its presence alone can't be used to tell whether any specific
/// email is registered or confirmed. See LoginScreen's doc comment
/// on _friendlyError for the leak this is working around.
const _resendHintThreshold = 2;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _isGoogleLoading = false;
  bool _isGitHubLoading = false;
  bool _obscurePassword = true;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    // A different email means a different account context - the resend
    // hint shouldn't carry over from whatever was typed before.
    _emailController.addListener(_resetAttemptsOnEmailChange);
  }

  String _lastEmailAtFailure = '';

  void _resetAttemptsOnEmailChange() {
    if (_emailController.text.trim() != _lastEmailAtFailure && _failedAttempts > 0) {
      setState(() => _failedAttempts = 0);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_resetAttemptsOnEmailChange);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Defense-in-depth only — actual authentication and rate-limiting
  /// happen server-side via Supabase's GoTrue service.
  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your email';
    if (trimmed.length > 254) return 'Email is too long';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (value.length > 128) return 'Password is too long';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigation on success is handled by RouteGuards reacting to the
      // auth state change — no explicit context.go(...) needed here.
    } on Exception catch (e) {
      // Debug-only: the SnackBar below is fully generic (see
      // _friendlyError's doc comment) - this is the only place the
      // real cause is visible when diagnosing a login failure.
      assert(() {
        debugPrint('Login failed: $e');
        return true;
      }());
      if (!mounted) return;
      setState(() {
        _failedAttempts++;
        _lastEmailAtFailure = _emailController.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendConfirmation() async {
    final email = _emailController.text.trim();
    if (_validateEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email above first.')),
      );
      return;
    }

    setState(() => _isResending = true);

    // Deliberately doesn't branch on success vs failure here - Supabase's
    // resend() throws differently depending on whether the email exists,
    // is already confirmed, etc. Surfacing any of that would recreate
    // the exact account-enumeration leak this whole flow exists to avoid.
    // One message, always, regardless of outcome; real cause still
    // visible via debugPrint for our own troubleshooting.
    try {
      await ref.read(authRepositoryProvider).resendConfirmationEmail(email);
    } catch (e) {
      assert(() {
        debugPrint('resendConfirmationEmail failed (shown generically): $e');
        return true;
      }());
    }

    if (!mounted) return;
    setState(() => _isResending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("If that email needs confirming, we've sent a new link.")),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // The browser has launched; the actual session arrives later via
      // the auth-state listener once the redirect completes, so there's
      // nothing further to do here on success.
    } catch (e) {
      assert(() {
        debugPrint('Google sign-in failed: $e');
        return true;
      }());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't sign in with Google. Please try again."),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleGitHubSignIn() async {
    setState(() => _isGitHubLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGitHub();
    } catch (e) {
      assert(() {
        debugPrint('GitHub sign-in failed: $e');
        return true;
      }());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't sign in with GitHub. Please try again."),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGitHubLoading = false);
    }
  }

  /// Deliberately collapses every failure into the same message. An
  /// earlier version distinguished "email not confirmed" from wrong
  /// credentials, which - while a common convenience in many apps -
  /// confirms an account with that email exists and is registered but
  /// unconfirmed. That's exactly the kind of account-existence leak
  /// this app's auth-error policy rules out, so it's gone now. The
  /// resend-confirmation hint below (shown by attempt count, not by
  /// detected cause) is the safe way back in for a genuinely
  /// unconfirmed user without reintroducing that leak.
  String _friendlyError(Exception e) {
    return 'Incorrect email or password.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: _validateLoginPassword,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.pushNamed(RouteNames.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                ),

                if (_failedAttempts >= _resendHintThreshold) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.outlineColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Still having trouble? If you recently signed up, you may need to "
                              'confirm your email first.',
                          style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _isResending ? null : _handleResendConfirmation,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: _isResending
                                ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Text('Resend confirmation email'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.secondary,
                      ),
                    )
                        : const Text(
                      'Sign In',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: Divider(color: context.outlineColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: context.outlineColor)),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                    icon: _isGoogleLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const _GoogleMonogram(),
                    label: Text(
                      _isGoogleLoading ? 'Signing in…' : 'Continue with Google',
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.outlineColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isGitHubLoading ? null : _handleGitHubSignIn,
                    icon: _isGitHubLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Icon(Icons.code, color: context.textPrimary, size: 20),
                    label: Text(
                      _isGitHubLoading ? 'Signing in…' : 'Continue with GitHub',
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.outlineColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: context.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.pushNamed(RouteNames.roleSelection),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple "G" monogram for the Google button - avoids pulling in an
/// icon-pack dependency just for one brand mark. Not pixel-identical
/// to Google's official multi-color logo, but reads clearly at button
/// size and needs no new package.
class _GoogleMonogram extends StatelessWidget {
  const _GoogleMonogram();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4285F4), width: 1.5),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}