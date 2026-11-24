import 'package:cloud_firestore/cloud_firestore.dart';

/// Blood Request model corresponding to the 'blood_requests' Firestore collection.
class BloodRequestModel {
  final String requestId;
  final String requesterId;
  final String requesterName;
  final String? requesterPhotoUrl;
  final String createdByRole; // 'user' or 'admin'
  final String patientName;
  final String bloodGroup;
  final num units;
  final String hospitalName;
  final String hospitalAddress;
  final String city;
  final String contactNumber;
  final String urgency; // 'Normal', 'Urgent', 'Critical'
  final String
  status; // 'pending', 'approved', 'rejected', 'fulfilled', 'cancelled'
  final String visibility; // 'private', 'published'
  final String? adminDecisionBy;
  final DateTime? adminDecisionAt;
  final String? rejectionReason;
  final bool isRepublished;
  final DateTime? republishedAt;
  final DateTime? feedUpdatedAt;
  final DateTime? reopenedAt;

  // Donor acceptance & completion fields
  final String? donorId;
  final String? donorName;
  final String? donorPhotoUrl;
  final String? donorPhone;
  final String? donorBloodGroup;
  final String? donorCity;
  final DateTime? acceptedAt;
  final String?
  donationStatus; // 'waiting_donor', 'donor_accepted', 'pending_verification', 'verified', 'completed', 'not_completed'
  final num? confirmedUnits;
  final DateTime? confirmedAt;
  final String? completionNotes;
  final String? lastReleasedDonorId;
  final String? lastReleasedReason;
  final DateTime? lastReleasedAt;
  final Map<String, dynamic>? lastUnsuccessfulAttempt;
  final String? unsuccessfulAttemptReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  BloodRequestModel({
    required this.requestId,
    required this.requesterId,
    this.requesterName = '',
    this.requesterPhotoUrl,
    this.createdByRole = 'user',
    required this.patientName,
    required this.bloodGroup,
    required this.units,
    required this.hospitalName,
    this.hospitalAddress = 'Rajkot, Gujarat',
    this.city = 'Rajkot',
    required this.contactNumber,
    this.urgency = 'Normal',
    this.status = 'pending',
    this.visibility = 'private',
    this.adminDecisionBy,
    this.adminDecisionAt,
    this.rejectionReason,
    this.isRepublished = false,
    this.republishedAt,
    this.feedUpdatedAt,
    this.reopenedAt,
    this.donorId,
    this.donorName,
    this.donorPhotoUrl,
    this.donorPhone,
    this.donorBloodGroup,
    this.donorCity,
    this.acceptedAt,
    this.donationStatus,
    this.confirmedUnits,
    this.confirmedAt,
    this.completionNotes,
    this.lastReleasedDonorId,
    this.lastReleasedReason,
    this.lastReleasedAt,
    this.lastUnsuccessfulAttempt,
    this.unsuccessfulAttemptReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  num get unitsRequired => units;
  String get contactPhone => contactNumber;
  DateTime? get donorAcceptedAt => acceptedAt;

  DateTime get effectiveFeedTime =>
      feedUpdatedAt ?? reopenedAt ?? republishedAt ?? createdAt;
  bool get isReopened => reopenedAt != null;

  bool get isPublished => visibility == 'published';
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  bool get hasConfirmedDonor => donorId != null && donorId!.trim().isNotEmpty;
  bool get isDonationAccepted => donationStatus == 'donor_accepted';
  bool get isPendingVerification => donationStatus == 'pending_verification';
  bool get isVerified => donationStatus == 'verified';
  bool get isDonationCompleted =>
      donationStatus == 'completed' || donationStatus == 'verified';
  bool get isDonationNotCompleted => donationStatus == 'not_completed';

  String get displayRequesterName {
    if (requesterName.trim().isNotEmpty) {
      return requesterName.trim();
    }
    return 'LifeLink Member';
  }

  String get displayDonorName {
    if (donorName != null && donorName!.trim().isNotEmpty) {
      return donorName!.trim();
    }
    return 'Anonymous Donor';
  }

  factory BloodRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BloodRequestModel.fromMap(doc.id, data);
  }

  factory BloodRequestModel.fromMap(String id, Map<String, dynamic> data) {
    return BloodRequestModel(
      requestId: id,
      requesterId: data['requesterId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? '',
      requesterPhotoUrl: data['requesterPhotoUrl'] as String?,
      createdByRole: data['createdByRole'] as String? ?? 'user',
      patientName: data['patientName'] as String? ?? '',
      bloodGroup: data['bloodGroup'] as String? ?? '',
      units: (data['unitsRequired'] ?? data['units']) as num? ?? 1,
      hospitalName: data['hospitalName'] as String? ?? '',
      hospitalAddress: data['hospitalAddress'] as String? ?? '',
      city: data['city'] as String? ?? 'Rajkot',
      contactNumber:
          (data['contactPhone'] ?? data['contactNumber']) as String? ?? '',
      urgency: data['urgency'] as String? ?? 'Normal',
      status: data['status'] as String? ?? 'pending',
      visibility: data['visibility'] as String? ?? 'private',
      adminDecisionBy: data['adminDecisionBy'] as String?,
      adminDecisionAt: _parseDateTime(data['adminDecisionAt']),
      rejectionReason: (data['rejectionReason'] ?? data['reason']) as String?,
      isRepublished: data['isRepublished'] as bool? ?? false,
      republishedAt: _parseDateTime(data['republishedAt']),
      feedUpdatedAt: _parseDateTime(data['feedUpdatedAt']),
      reopenedAt: _parseDateTime(data['reopenedAt']),
      donorId: data['donorId'] as String?,
      donorName: data['donorName'] as String?,
      donorPhotoUrl: data['donorPhotoUrl'] as String?,
      donorPhone: data['donorPhone'] as String?,
      donorBloodGroup: data['donorBloodGroup'] as String?,
      donorCity: data['donorCity'] as String?,
      acceptedAt: _parseDateTime(data['acceptedAt']),
      donationStatus: data['donationStatus'] as String?,
      confirmedUnits: data['confirmedUnits'] as num?,
      confirmedAt: _parseDateTime(data['confirmedAt']),
      completionNotes: data['completionNotes'] as String?,
      lastReleasedDonorId: data['lastReleasedDonorId'] as String?,
      lastReleasedReason: data['lastReleasedReason'] as String?,
      lastReleasedAt: _parseDateTime(data['lastReleasedAt']),
      lastUnsuccessfulAttempt: _parseUnsuccessfulAttempt(
        data['lastUnsuccessfulAttempt'],
      ),
      unsuccessfulAttemptReason: data['unsuccessfulAttemptReason'] as String?,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhotoUrl': requesterPhotoUrl,
      'createdByRole': createdByRole,
      'patientName': patientName,
      'bloodGroup': bloodGroup,
      'units': units,
      'unitsRequired': units,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'city': city,
      'contactNumber': contactNumber,
      'contactPhone': contactNumber,
      'urgency': urgency,
      'status': status,
      'visibility': visibility,
      'adminDecisionBy': adminDecisionBy,
      'adminDecisionAt': adminDecisionAt != null
          ? Timestamp.fromDate(adminDecisionAt!)
          : null,
      'rejectionReason': rejectionReason,
      'isRepublished': isRepublished,
      'republishedAt': republishedAt != null
          ? Timestamp.fromDate(republishedAt!)
          : null,
      if (feedUpdatedAt != null)
        'feedUpdatedAt': Timestamp.fromDate(feedUpdatedAt!),
      if (reopenedAt != null) 'reopenedAt': Timestamp.fromDate(reopenedAt!),
      'donorId': (donorId != null && donorId!.trim().isNotEmpty)
          ? donorId
          : null,
      'donorName': (donorName != null && donorName!.trim().isNotEmpty)
          ? donorName
          : null,
      'donorPhotoUrl':
          (donorPhotoUrl != null && donorPhotoUrl!.trim().isNotEmpty)
          ? donorPhotoUrl
          : null,
      'donorPhone': (donorPhone != null && donorPhone!.trim().isNotEmpty)
          ? donorPhone
          : null,
      'donorBloodGroup':
          (donorBloodGroup != null && donorBloodGroup!.trim().isNotEmpty)
          ? donorBloodGroup
          : null,
      'donorCity': (donorCity != null && donorCity!.trim().isNotEmpty)
          ? donorCity
          : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'donationStatus': donationStatus,
      'confirmedUnits': confirmedUnits,
      'confirmedAt': confirmedAt != null
          ? Timestamp.fromDate(confirmedAt!)
          : null,
      'completionNotes': completionNotes,
      if (lastReleasedDonorId != null)
        'lastReleasedDonorId': lastReleasedDonorId,
      if (lastReleasedReason != null) 'lastReleasedReason': lastReleasedReason,
      if (lastReleasedAt != null)
        'lastReleasedAt': Timestamp.fromDate(lastReleasedAt!),
      if (lastUnsuccessfulAttempt != null)
        'lastUnsuccessfulAttempt': lastUnsuccessfulAttempt,
      if (unsuccessfulAttemptReason != null)
        'unsuccessfulAttemptReason': unsuccessfulAttemptReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BloodRequestModel copyWith({
    String? requesterName,
    String? requesterPhotoUrl,
    String? patientName,
    String? bloodGroup,
    num? units,
    String? hospitalName,
    String? hospitalAddress,
    String? city,
    String? contactNumber,
    String? urgency,
    String? status,
    String? visibility,
    String? adminDecisionBy,
    DateTime? adminDecisionAt,
    String? rejectionReason,
    bool? isRepublished,
    DateTime? republishedAt,
    DateTime? feedUpdatedAt,
    DateTime? reopenedAt,
    bool clearDonor = false,
    String? donorId,
    String? donorName,
    String? donorPhotoUrl,
    String? donorPhone,
    String? donorBloodGroup,
    String? donorCity,
    DateTime? acceptedAt,
    String? donationStatus,
    num? confirmedUnits,
    DateTime? confirmedAt,
    String? completionNotes,
    String? lastReleasedDonorId,
    String? lastReleasedReason,
    DateTime? lastReleasedAt,
    Map<String, dynamic>? lastUnsuccessfulAttempt,
    String? unsuccessfulAttemptReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodRequestModel(
      requestId: requestId,
      requesterId: requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhotoUrl: requesterPhotoUrl ?? this.requesterPhotoUrl,
      createdByRole: createdByRole,
      patientName: patientName ?? this.patientName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      units: units ?? this.units,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      city: city ?? this.city,
      contactNumber: contactNumber ?? this.contactNumber,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      adminDecisionBy: adminDecisionBy ?? this.adminDecisionBy,
      adminDecisionAt: adminDecisionAt ?? this.adminDecisionAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isRepublished: isRepublished ?? this.isRepublished,
      republishedAt: republishedAt ?? this.republishedAt,
      feedUpdatedAt: feedUpdatedAt ?? this.feedUpdatedAt,
      reopenedAt: reopenedAt ?? this.reopenedAt,
      donorId: clearDonor ? null : (donorId ?? this.donorId),
      donorName: clearDonor ? null : (donorName ?? this.donorName),
      donorPhotoUrl: clearDonor ? null : (donorPhotoUrl ?? this.donorPhotoUrl),
      donorPhone: clearDonor ? null : (donorPhone ?? this.donorPhone),
      donorBloodGroup: clearDonor
          ? null
          : (donorBloodGroup ?? this.donorBloodGroup),
      donorCity: clearDonor ? null : (donorCity ?? this.donorCity),
      acceptedAt: clearDonor ? null : (acceptedAt ?? this.acceptedAt),
      donationStatus: donationStatus ?? this.donationStatus,
      confirmedUnits: clearDonor
          ? null
          : (confirmedUnits ?? this.confirmedUnits),
      confirmedAt: clearDonor ? null : (confirmedAt ?? this.confirmedAt),
      completionNotes: clearDonor
          ? null
          : (completionNotes ?? this.completionNotes),
      lastReleasedDonorId: lastReleasedDonorId ?? this.lastReleasedDonorId,
      lastReleasedReason: lastReleasedReason ?? this.lastReleasedReason,
      lastReleasedAt: lastReleasedAt ?? this.lastReleasedAt,
      lastUnsuccessfulAttempt:
          lastUnsuccessfulAttempt ?? this.lastUnsuccessfulAttempt,
      unsuccessfulAttemptReason:
          unsuccessfulAttemptReason ?? this.unsuccessfulAttemptReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Accepts both the intended map payload and the legacy Timestamp value
  /// written by older versions of reportDonationDidNotHappen().
  /// A malformed historical record must never crash the entire request feed.
  static Map<String, dynamic>? _parseUnsuccessfulAttempt(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Timestamp || value is DateTime || value is String) {
      return <String, dynamic>{'at': value};
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
