/// Spacing scale from Phase 1's design system (4 / 8 / 12 / 16 / 24 / 32 / 48).
/// Using named constants instead of raw numbers keeps padding/margins
/// consistent across every screen and makes a global density change a
/// one-file edit.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Common radii, aligned to the "16-20px cards / 12px chips / pill" rule
  static const double radiusChip = 12;
  static const double radiusCard = 18;
  static const double radiusSheet = 24;
  static const double radiusPill = 999;
}
