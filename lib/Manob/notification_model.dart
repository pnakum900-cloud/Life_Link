import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification model corresponding to the 'notifications' Firestore collection.
class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final String type; // 'request_status', 'alert', 'donation', 'system'
  final String? relatedRequestId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'request_status',
    this.relatedRequestId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      notificationId: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'request_status',
      relatedRequestId: data['relatedRequestId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      notificationId: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'request_status',
      relatedRequestId: data['relatedRequestId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedRequestId': relatedRequestId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedRequestId: relatedRequestId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
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
