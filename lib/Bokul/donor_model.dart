import 'package:cloud_firestore/cloud_firestore.dart';

/// Donor profile model corresponding to the 'donor_profiles' Firestore collection.
class DonorModel {
  final String userId; // Authenticated Firebase UID (doc ID)
  final String fullName;
  final String bloodGroup; // A+, A-, B+, B-, AB+, AB-, O+, O-
  final String phoneNumber;
  final String address;
  final String city;
  final bool isAvailable;
  final String
  eligibilityStatus; // 'READY', 'NOT READY', 'eligible', 'pending_screening'
  final String role; // 'user' or 'admin'
  final String? profileImageUrl;
  final DateTime? lastDonationAt;
  final String? lastVerifiedDonationId;
  final int totalDonationCount;
  final num totalUnitsDonated;
  final DateTime createdAt;
  final DateTime updatedAt;

  DonorModel({
    required this.userId,
    required this.fullName,
    required this.bloodGroup,
    required this.phoneNumber,
    required this.address,
    this.city = 'Rajkot',
    this.isAvailable = true,
    this.eligibilityStatus = 'READY',
    this.role = 'user',
    this.profileImageUrl,
    this.lastDonationAt,
    this.lastVerifiedDonationId,
    this.totalDonationCount = 0,
    this.totalUnitsDonated = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isReady =>
      eligibilityStatus.toUpperCase() == 'READY' ||
      eligibilityStatus.toLowerCase() == 'eligible';

  bool get isCooldown =>
      eligibilityStatus.toUpperCase() == 'COOLDOWN' ||
      eligibilityStatus.toUpperCase() == 'RECOVERY';

  bool get isEligibleToDonate => !isAdmin && isAvailable && isReady;

  bool get isAdmin => role == 'admin';

  /// Blood group compatibility check: returns true if [donorGroup] can donate to [recipientGroup].
  static bool isBloodCompatible(String donorGroup, String recipientGroup) {
    final d = donorGroup.trim().toUpperCase();
    final r = recipientGroup.trim().toUpperCase();
    if (d.isEmpty || r.isEmpty) return false;
    if (d == r) return true;
    if (d == 'O-') return true; // Universal donor
    if (d == 'O+') return r == 'O+' || r == 'A+' || r == 'B+' || r == 'AB+';
    if (d == 'A-') return r == 'A-' || r == 'A+' || r == 'AB-' || r == 'AB+';
    if (d == 'A+') return r == 'A+' || r == 'AB+';
    if (d == 'B-') return r == 'B-' || r == 'B+' || r == 'AB-' || r == 'AB+';
    if (d == 'B+') return r == 'B+' || r == 'AB+';
    if (d == 'AB-') return r == 'AB-' || r == 'AB+';
    if (d == 'AB+') return r == 'AB+';
    return false;
  }

  factory DonorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DonorModel(
      userId: doc.id,
      fullName: data['fullName'] as String? ?? '',
      bloodGroup: data['bloodGroup'] as String? ?? 'A+',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? 'Rajkot',
      isAvailable: data['isAvailable'] as bool? ?? true,
      eligibilityStatus: data['eligibilityStatus'] as String? ?? 'READY',
      role: data['role'] as String? ?? 'user',
      profileImageUrl: data['profileImageUrl'] as String?,
      lastDonationAt: _parseDateTime(data['lastDonationAt']),
      lastVerifiedDonationId: data['lastVerifiedDonationId'] as String?,
      totalDonationCount: (data['totalDonationCount'] as num?)?.toInt() ?? 0,
      totalUnitsDonated: data['totalUnitsDonated'] as num? ?? 0,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  factory DonorModel.fromMap(String userId, Map<String, dynamic> data) {
    return DonorModel(
      userId: userId,
      fullName: data['fullName'] as String? ?? '',
      bloodGroup: data['bloodGroup'] as String? ?? 'A+',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? 'Rajkot',
      isAvailable: data['isAvailable'] as bool? ?? true,
      eligibilityStatus: data['eligibilityStatus'] as String? ?? 'READY',
      role: data['role'] as String? ?? 'user',
      profileImageUrl: data['profileImageUrl'] as String?,
      lastDonationAt: _parseDateTime(data['lastDonationAt']),
      lastVerifiedDonationId: data['lastVerifiedDonationId'] as String?,
      totalDonationCount: (data['totalDonationCount'] as num?)?.toInt() ?? 0,
      totalUnitsDonated: data['totalUnitsDonated'] as num? ?? 0,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'bloodGroup': bloodGroup,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'isAvailable': isAvailable,
      'eligibilityStatus': eligibilityStatus,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'lastDonationAt': lastDonationAt != null
          ? Timestamp.fromDate(lastDonationAt!)
          : null,
      'lastVerifiedDonationId': lastVerifiedDonationId,
      'totalDonationCount': totalDonationCount,
      'totalUnitsDonated': totalUnitsDonated,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DonorModel copyWith({
    String? fullName,
    String? bloodGroup,
    String? phoneNumber,
    String? address,
    String? city,
    bool? isAvailable,
    String? eligibilityStatus,
    String? role,
    String? profileImageUrl,
    DateTime? lastDonationAt,
    String? lastVerifiedDonationId,
    int? totalDonationCount,
    num? totalUnitsDonated,
    DateTime? updatedAt,
  }) {
    return DonorModel(
      userId: userId,
      fullName: fullName ?? this.fullName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      isAvailable: isAvailable ?? this.isAvailable,
      eligibilityStatus: eligibilityStatus ?? this.eligibilityStatus,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lastDonationAt: lastDonationAt ?? this.lastDonationAt,
      lastVerifiedDonationId:
          lastVerifiedDonationId ?? this.lastVerifiedDonationId,
      totalDonationCount: totalDonationCount ?? this.totalDonationCount,
      totalUnitsDonated: totalUnitsDonated ?? this.totalUnitsDonated,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
