import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin action audit log model corresponding to 'admin_logs' Firestore collection.
class AdminLogModel {
  final String logId;
  final String actorId;
  final String adminId;
  final String adminName;
  final String? actorName;
  final String? actorPhotoUrl;
  final String? title;
  final String? description;
  final String
  action; // 'request_approved', 'request_rejected', 'request_republished', 'request_accepted', 'donation_completed', etc.
  final String targetCollection;
  final String targetId;
  final Map<String, dynamic>? details;
  final bool isRead;
  final DateTime createdAt;

  AdminLogModel({
    required this.logId,
    String? actorId,
    required this.adminId,
    this.adminName = 'System Admin',
    this.actorName,
    this.actorPhotoUrl,
    this.title,
    this.description,
    required this.action,
    required this.targetCollection,
    required this.targetId,
    this.details,
    this.isRead = false,
    DateTime? createdAt,
  }) : actorId = (actorId != null && actorId.isNotEmpty) ? actorId : adminId,
       createdAt = createdAt ?? DateTime.now();

  String get entityType => targetCollection;
  String get entityId => targetId;

  String get displayActorName {
    if (actorName != null && actorName!.trim().isNotEmpty) {
      return actorName!.trim();
    }
    if (adminName.trim().isNotEmpty && adminName != 'System Admin') {
      return adminName.trim();
    }
    return 'LifeLink User';
  }

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    switch (action) {
      case 'request_approved':
        return 'Blood Request Approved & Published';
      case 'request_rejected':
        return 'Blood Request Rejected';
      case 'request_republished':
        return 'Blood Request Republished';
      case 'request_accepted':
        return 'Donor Accepted Blood Request';
      case 'donation_completed':
        return 'Donation Completed & Confirmed';
      case 'donation_did_not_happen':
        return 'Donation Did Not Happen';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get displayDescription {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    final det = details;
    final patient = det?['patientName'] ?? 'patient';
    final group = det?['bloodGroup'] ?? '';
    final units = det?['units'] ?? '';
    switch (action) {
      case 'request_approved':
        return 'Blood request for $patient ($group, $units units) was approved and published.';
      case 'request_rejected':
        final reason = det?['reason'] ?? 'No reason provided';
        return 'Blood request for $patient ($group) was rejected. Reason: $reason.';
      case 'request_republished':
        return 'Blood request for $patient was republished and is visible to donors.';
      case 'request_accepted':
        final donor = det?['donorName'] ?? 'Donor';
        return '$donor accepted request for $patient.';
      case 'donation_completed':
        final confirmedUnits = det?['confirmedUnits'] ?? units;
        return 'Requester confirmed completion of donation ($confirmedUnits units).';
      case 'donation_did_not_happen':
        final reason = det?['reason'] ?? 'Not specified';
        return 'Requester reported donation did not occur ($reason).';
      default:
        return 'Action logged on $targetCollection.';
    }
  }

  factory AdminLogModel.fromMap(String logId, Map<String, dynamic> data) {
    final detailsMap = data['details'] as Map<String, dynamic>?;
    final fallbackActorName =
        detailsMap?['donorName'] ??
        detailsMap?['requesterName'] ??
        detailsMap?['patientName'];

    return AdminLogModel(
      logId: logId,
      actorId: data['actorId'] as String? ?? data['adminId'] as String? ?? '',
      adminId: data['adminId'] as String? ?? data['actorId'] as String? ?? '',
      adminName: data['adminName'] as String? ?? 'System Admin',
      actorName: data['actorName'] as String? ?? (fallbackActorName as String?),
      actorPhotoUrl: data['actorPhotoUrl'] as String?,
      title: data['title'] as String?,
      description: data['description'] as String?,
      action: data['action'] as String? ?? '',
      targetCollection:
          (data['entityType'] ?? data['targetCollection']) as String? ??
          'general',
      targetId: (data['entityId'] ?? data['targetId']) as String? ?? '',
      details: detailsMap,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  factory AdminLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminLogModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'actorId': actorId,
      'adminId': adminId.isNotEmpty ? adminId : actorId,
      'adminName': adminName,
      'actorName': actorName,
      'actorPhotoUrl': actorPhotoUrl,
      'title': title,
      'description': description,
      'action': action,
      'targetCollection': targetCollection,
      'entityType': targetCollection,
      'targetId': targetId,
      'entityId': targetId,
      'details': details,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
