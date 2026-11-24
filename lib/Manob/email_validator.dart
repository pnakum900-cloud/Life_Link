/// Email validator enforcing @gmail.com and @rku.ac.in email domains.
///
/// Both user and admin accounts must have an email ending with @gmail.com
/// or @rku.ac.in.
class EmailValidator {
  static const List<String> allowedDomains = ['gmail.com', 'rku.ac.in'];

  /// Standard email regex checking general email structure.
  static final RegExp _emailFormatRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Normalizes an email address: trims whitespace and lowercases the address.
  static String normalize(String? email) {
    if (email == null) return '';
    return email.trim().toLowerCase();
  }

  /// Extracts the domain from an email address (lowercased).
  static String? extractDomain(String email) {
    final normalized = normalize(email);
    final atIndex = normalized.lastIndexOf('@');
    if (atIndex == -1 || atIndex == normalized.length - 1) return null;
    return normalized.substring(atIndex + 1);
  }

  /// Checks if an email is valid and belongs to an allowed domain.
  static bool isValid(String? email) {
    if (email == null) return false;
    final normalized = normalize(email);
    if (normalized.isEmpty) return false;
    if (!_emailFormatRegex.hasMatch(normalized)) return false;

    final domain = extractDomain(normalized);
    if (domain == null) return false;

    // Check exact domain match against allowed domains (preventing subdomains like .example.com)
    return allowedDomains.contains(domain);
  }

  /// Form field validator for Flutter widgets.
  /// Returns null if valid, or an error message string if invalid.
  static String? validate(String? value, {String fieldLabel = 'Email'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required';
    }

    final normalized = normalize(value);
    if (!_emailFormatRegex.hasMatch(normalized)) {
      return 'Enter a valid email address';
    }

    final domain = extractDomain(normalized);
    if (domain == null || !allowedDomains.contains(domain)) {
      return 'Only @gmail.com and @rku.ac.in emails are allowed';
    }

    return null;
  }
}
