/// Shared form validation (no automatic email lowercasing).
class FormValidators {
  FormValidators._();

  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? loginEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (v.length > 100) return 'Email must be at most 100 characters';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? loginPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length > 64) return 'Password must be at most 64 characters';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length > 50) return 'Name must be at most 50 characters';
    return null;
  }

  static String? registerEmail(String? value) {
    return loginEmail(value);
  }

  static String? registerPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    if (v.length > 64) return 'Password must be at most 64 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  /// Optional: empty is valid; if non-empty, digits only, exactly 10 digits.
  static String? phoneOptional(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(raw)) {
      return 'Phone must contain digits only';
    }
    if (raw.length != 10) {
      return 'Phone must be exactly 10 digits';
    }
    return null;
  }

  static String? preferredCinemaOptional(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > 60) return 'Preferred cinema must be at most 60 characters';
    return null;
  }

  static String? favouriteGenreOptional(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > 40) return 'Favourite genre must be at most 40 characters';
    return null;
  }
}
