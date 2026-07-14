/// Pure validation functions for form fields. Returns `null` when valid,
/// or a user-facing error string when invalid — matching the signature
/// Flutter's `TextFormField.validator` expects directly.
class Validators {
  const Validators._();

  static final RegExp _emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
  static final RegExp _pakistaniPhoneRegex = RegExp(r'^(\+92|0)?3\d{9}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Include at least one uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Include at least one number';
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != originalPassword) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name is too short';
    return null;
  }

  /// Accepts Pakistani mobile formats: 03XXXXXXXXX or +923XXXXXXXXX.
  static String? pakistaniPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(' ', '').replaceAll('-', '');
    if (!_pakistaniPhoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid Pakistani mobile number';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? maxLength(String? value, int max, {String fieldName = 'This field'}) {
    if (value != null && value.length > max) {
      return '$fieldName must be $max characters or fewer';
    }
    return null;
  }
}
