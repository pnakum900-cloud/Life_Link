import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model corresponding to the 'users' Firestore collection.
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role; // 'user' or 'admin'
  final String accountStatus; // 'active', 'suspended', 'disabled'
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.role = 'user',
    this.accountStatus = 'active',
    this.profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';
  bool get isActive => accountStatus == 'active';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      accountStatus: data['accountStatus'] as String? ?? 'active',
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String? ?? uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      accountStatus: data['accountStatus'] as String? ?? 'active',
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'accountStatus': accountStatus,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? accountStatus,
    String? profileImageUrl,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
