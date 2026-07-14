import 'package:flutter/material.dart';

import 'package:aina/core/theme/app_colors.dart';

/// Renders a salon's cover photo when [imageUrl] is available; otherwise
/// falls back to a branded gradient card showing the salon's initial(s)
/// instead of a generic placeholder icon.
///
/// The gradient/initial combination is derived deterministically from the
/// salon name, so the same salon always gets the same look across the app.
class SalonCoverImage extends StatelessWidget {
  const SalonCoverImage({
    super.key,
    required this.name,
    this.imageUrl,
    this.borderRadius,
  });

  final String name;
  final String? imageUrl;
  final BorderRadius? borderRadius;

  // A small rotation of on-brand gradient pairs so cards don't all look
  // identical when many salons in a row lack real photos.
  static const List<List<Color>> _gradients = [
    [AppColors.secondary, AppColors.accent],
    [AppColors.accent, AppColors.primaryDark],
    [AppColors.primaryDark, AppColors.secondary],
    [AppColors.secondary, AppColors.primary],
  ];

  String get _initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  List<Color> get _gradient {
    final index = name.codeUnits.fold<int>(0, (sum, c) => sum + c) % _gradients.length;
    return _gradients[index];
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => _FallbackCard(
            initials: _initials,
            gradient: _gradient,
            borderRadius: radius,
          ),
        ),
      );
    }

    return _FallbackCard(
      initials: _initials,
      gradient: _gradient,
      borderRadius: radius,
    );
  }
}

class _FallbackCard extends StatelessWidget {
  const _FallbackCard({
    required this.initials,
    required this.gradient,
    required this.borderRadius,
  });

  final String initials;
  final List<Color> gradient;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle decorative ring behind the initials, echoing the
            // Halo/Aina "corona" motif rather than a plain flat fill.
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),
            Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}