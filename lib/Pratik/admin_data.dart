/// Admin data constants and dynamic repository bridge.
/// Predefined blood groups are kept as UI constants,
/// while runtime database records are managed via Firestore services.
class AdminData {
  // Predefined blood group choices for dropdowns and filters
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Dynamic lists populated only from real database operations
  static List<Map<String, dynamic>> donors = [];
  static List<Map<String, dynamic>> requests = [];
  static List<Map<String, dynamic>> alerts = [];
  static List<Map<String, dynamic>> users = [];
}
