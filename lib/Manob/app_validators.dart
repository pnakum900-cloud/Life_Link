import 'email_validator.dart';

/// Centralized application validator for LifeLink.
///
/// Provides consistent, field-appropriate validation across all forms,
/// services, and user/admin interfaces.
class AppValidators {
  static const List<String> validBloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const String defaultCity = 'Rajkot';

  /// Validates person name fields (full name, patient name, etc.).
  ///
  /// - Required.
  /// - At least [minLength] (default 3) non-whitespace characters.
  /// - Rejects strings containing only whitespace.
  /// - Maximum [maxLength] (default 50) characters.
  /// - Rejects strings with digits or disallowed symbols.
  static String? validateName(
    String? value, {
    String fieldLabel = 'Full Name',
    int minLength = 3,
    int maxLength = 50,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return '$fieldLabel must be at least $minLength characters';
    }
    if (trimmed.length > maxLength) {
      return '$fieldLabel cannot exceed $maxLength characters';
    }
    // Allow alphabets, spaces, dots, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\.\-']+$");
    if (!nameRegex.hasMatch(trimmed)) {
      return '$fieldLabel can only contain letters and spaces';
    }
    return null;
  }

  /// Validates required patient name.
  static String? validatePatientName(String? value) {
    return validateName(
      value,
      fieldLabel: 'Patient Name',
      minLength: 3,
      maxLength: 50,
    );
  }

  /// Validates email address syntax and domain restrictions (@gmail.com or @rku.ac.in).
  static String? validateEmail(String? value, {String fieldLabel = 'Email'}) {
    return EmailValidator.validate(value, fieldLabel: fieldLabel);
  }

  /// Validates password fields.
  ///
  /// [isNewPassword]: When true (registration, reset password), enforces at least 8 characters
  /// with a mix of letters and digits.
  /// When false (login), ensures the field is not empty and has a usable length without
  /// locking out accounts created under legacy minimums.
  static String? validatePassword(String? value, {bool isNewPassword = false}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (isNewPassword) {
      if (value.length < 8) {
        return 'Password must be at least 8 characters long';
      }
      final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
      final hasDigit = RegExp(r'[0-9]').hasMatch(value);
      if (!hasLetter || !hasDigit) {
        return 'Password must include both letters and numbers';
      }
    } else {
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
    }
    return null;
  }

  /// Validates confirm-password matching.
  static String? validateConfirmPassword(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates Indian mobile numbers (10 digits starting with 6-9).
  static String? validatePhone(
    String? value, {
    String fieldLabel = 'Phone Number',
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return '$fieldLabel is required';
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid 10-digit mobile number (e.g., 9876543210)';
    }
    return null;
  }

  /// Convenience alias for validating an Indian mobile number.
  static String? validateIndianPhone(String? value) => validatePhone(value);

  /// Validates address or general required text.
  static String? validateAddressOrText(
    String? value, {
    String fieldName = 'Address',
    int minLength = 3,
    int maxLength = 120,
    bool isRequired = true,
  }) => validateAddress(
    value,
    fieldLabel: fieldName,
    minLength: minLength,
    maxLength: maxLength,
    isRequired: isRequired,
  );

  /// Validates required text addresses.
  static String? validateAddress(
    String? value, {
    String fieldLabel = 'Address',
    int minLength = 3,
    int maxLength = 120,
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return '$fieldLabel is required';
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return '$fieldLabel must be at least $minLength characters';
    }
    if (trimmed.length > maxLength) {
      return '$fieldLabel cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validates blood group selection.
  static String? validateBloodGroup(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a blood group';
    }
    if (!validBloodGroups.contains(value.trim().toUpperCase())) {
      return 'Invalid blood group selected';
    }
    return null;
  }

  /// Validates donation blood units (positive integer between [min] and [max]).
  static String? validateUnits(dynamic value, {int min = 1, int max = 10}) {
    if (value == null) return 'Units required is required';
    final str = value.toString().trim();
    if (str.isEmpty) return 'Units required is required';
    final parsed = int.tryParse(str);
    if (parsed == null || parsed < min) {
      return 'Enter a valid number of units (minimum $min)';
    }
    if (parsed > max) {
      return 'Maximum $max units permitted per request';
    }
    return null;
  }

  /// Validates hospital name.
  static String? validateHospitalName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Hospital name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Hospital name must be at least 3 characters';
    }
    if (trimmed.length > 80) {
      return 'Hospital name cannot exceed 80 characters';
    }
    return null;
  }

  /// Resolves city with guaranteed 'Rajkot' default for new profiles.
  static String resolveCity(String? city) {
    if (city == null || city.trim().isEmpty) {
      return defaultCity;
    }
    return city.trim();
  }
}
