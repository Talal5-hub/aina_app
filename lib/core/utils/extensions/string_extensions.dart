/// Small string helpers used across form fields, search, and display
/// formatting. Kept dependency-free (no intl/flutter imports) so this
/// file can be used from pure-Dart domain code too.
extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  bool get isNullOrEmptyTrimmed => trim().isEmpty;

  /// Truncates to [maxLength] characters, appending an ellipsis — used
  /// for salon descriptions/review previews in list cards.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength).trimRight()}…';
  }

  /// Converts "gulshan-e-iqbal" -> "Gulshan E Iqbal" for display when a
  /// slug needs to be shown as a fallback label.
  String slugToTitleCase() {
    return split('-').map((word) => word.capitalize()).join(' ');
  }

  /// Normalizes a Pakistani phone number to E.164 (+92XXXXXXXXXX) for
  /// consistent storage and WhatsApp deep-link generation.
  String toE164PakistaniPhone() {
    final digitsOnly = replaceAll(RegExp(r'[^\d+]'), '');
    if (digitsOnly.startsWith('+92')) return digitsOnly;
    if (digitsOnly.startsWith('0')) return '+92${digitsOnly.substring(1)}';
    if (digitsOnly.startsWith('92')) return '+$digitsOnly';
    return '+92$digitsOnly';
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String orDefault(String fallback) => (this == null || this!.isEmpty) ? fallback : this!;
}
