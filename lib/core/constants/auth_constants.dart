/// The custom URL scheme registered natively for this app:
/// - iOS: ios/Runner/Info.plist -> CFBundleURLSchemes
/// - Android: android/app/src/main/AndroidManifest.xml -> intent-filter data scheme
///
/// Supabase redirects here after the user taps a password-reset or
/// email-confirmation link, and `supabase_flutter`'s PKCE flow picks up
/// the incoming link automatically (no manual listener needed) as long
/// as this exact value is registered in the Supabase dashboard under
/// Authentication > URL Configuration > Redirect URLs.
class AuthConstants {
  const AuthConstants._();

  static const String redirectUrl = 'io.supabase.aina://login-callback';
}
