import 'package:intl/intl.dart';

/// Formatting helpers for values that appear repeatedly across salon,
/// service, and appointment screens — kept in one place so "PKR 4,500"
/// vs "Rs. 4500" vs "4500 PKR" isn't decided differently screen by screen.
class Formatters {
  const Formatters._();

  static final NumberFormat _pkrFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static String currency(num amount) => _pkrFormat.format(amount);

  static String distance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}min';
  }

  static String rating(num rating) => rating.toStringAsFixed(1);

  static String reviewCount(int count) {
    if (count == 0) return 'No reviews yet';
    if (count == 1) return '1 review';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k reviews';
    return '$count reviews';
  }

  static String discountPercentage(num original, num discounted) {
    final percentage = ((original - discounted) / original * 100).round();
    return '$percentage% OFF';
  }

  static String date(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  static String time(DateTime date) => DateFormat('h:mm a').format(date);

  static String dateTime(DateTime date) => DateFormat('MMM d, yyyy · h:mm a').format(date);

  /// "2h ago", "Yesterday", "3 days ago" style relative timestamps,
  /// used for reviews and notifications.
  static String relativeTime(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }
}
