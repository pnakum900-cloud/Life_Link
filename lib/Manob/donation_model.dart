import 'package:cloud_firestore/cloud_firestore.dart';

/// Donation record model corresponding to the 'donations' Firestore collection.
class DonationModel {
  final String donationId;
  final String donorId;
  final String donorName;
  final String? bloodRequestId;
  final String? requesterId;
  final String? requesterName;
  final String? patientName;
  final DateTime? donationDate;
  final String hospitalName;
  final String? hospitalAddress;
  final String bloodGroup;
  final num unitsDonated;
  final String
  status; // 'pending_verification', 'verified', 'completed', 'rejected'
  final bool confirmedByRequester;
  final String? verifiedBy;
  final String? recordedBy;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DonationModel({
    required this.donationId,
    required this.donorId,
    this.donorName = '',
    this.bloodRequestId,
    this.requesterId,
    this.requesterName,
    this.patientName,
    this.donationDate,
    required this.hospitalName,
    this.hospitalAddress,
    required this.bloodGroup,
    this.unitsDonated = 1,
    this.status = 'pending_verification',
    this.confirmedByRequester = true,
    this.verifiedBy,
    String? recordedBy,
    this.rejectionReason,
    this.verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : recordedBy = recordedBy ?? verifiedBy,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get id => donationId;
  String get hospitalLocation =>
      hospitalAddress != null && hospitalAddress!.isNotEmpty
      ? '$hospitalName, $hospitalAddress'
      : hospitalName;
  bool get isVerified => status == 'verified';
  bool get isPendingVerification =>
      status == 'pending_verification' || status == 'pending';
  bool get isPending => isPendingVerification;
  bool get isCompleted => status == 'completed' || status == 'verified';
  bool get isRejected => status == 'rejected';

  factory DonationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DonationModel.fromMap(doc.id, data);
  }

  factory DonationModel.fromMap(String id, Map<String, dynamic> data) {
    final recordedByVal = (data['recordedBy'] ?? data['verifiedBy']) as String?;
    return DonationModel(
      donationId: id,
      donorId: data['donorId'] as String? ?? '',
      donorName: data['donorName'] as String? ?? '',
      bloodRequestId: (data['bloodRequestId'] ?? data['requestId']) as String?,
      requesterId: data['requesterId'] as String?,
      requesterName: data['requesterName'] as String?,
      patientName: data['patientName'] as String?,
      donationDate: _parseDateTime(data['donationDate'] ?? data['donatedAt']),
      hospitalName: data['hospitalName'] as String? ?? 'Civil Hospital',
      hospitalAddress: data['hospitalAddress'] as String?,
      bloodGroup: data['bloodGroup'] as String? ?? 'O+',
      unitsDonated: data['unitsDonated'] as num? ?? 1,
      status: data['status'] as String? ?? 'pending_verification',
      confirmedByRequester: data['confirmedByRequester'] as bool? ?? true,
      verifiedBy: data['verifiedBy'] as String? ?? recordedByVal,
      recordedBy: recordedByVal,
      rejectionReason: data['rejectionReason'] as String?,
      verifiedAt: _parseDateTime(data['verifiedAt']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'bloodRequestId': bloodRequestId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'patientName': patientName,
      'donationDate': donationDate != null
          ? Timestamp.fromDate(donationDate!)
          : null,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'bloodGroup': bloodGroup,
      'unitsDonated': unitsDonated,
      'status': status,
      'confirmedByRequester': confirmedByRequester,
      'verifiedBy': verifiedBy ?? recordedBy,
      'recordedBy': recordedBy ?? verifiedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DonationModel copyWith({
    String? donorName,
    String? bloodRequestId,
    String? requesterId,
    String? requesterName,
    String? patientName,
    DateTime? donationDate,
    String? hospitalName,
    String? hospitalAddress,
    String? bloodGroup,
    num? unitsDonated,
    String? status,
    bool? confirmedByRequester,
    String? verifiedBy,
    String? rejectionReason,
    DateTime? verifiedAt,
    DateTime? updatedAt,
  }) {
    return DonationModel(
      donationId: donationId,
      donorId: donorId,
      donorName: donorName ?? this.donorName,
      bloodRequestId: bloodRequestId ?? this.bloodRequestId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      patientName: patientName ?? this.patientName,
      donationDate: donationDate ?? this.donationDate,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      unitsDonated: unitsDonated ?? this.unitsDonated,
      status: status ?? this.status,
      confirmedByRequester: confirmedByRequester ?? this.confirmedByRequester,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
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
