import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Manob/auth_service.dart';
import '../Manob/blood_request_model.dart';
import '../Manob/firebase_service.dart';
import '../Manob/user_model.dart';
import 'donor_model.dart';

class BloodRequestService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final CollectionReference _requestsCol = _firestore.collection(
    'blood_requests',
  );

  /// Parses each document independently. A malformed legacy record is logged
  /// and skipped instead of terminating the whole real-time feed.
  static List<BloodRequestModel> _parseRequestDocuments(
    Iterable<QueryDocumentSnapshot> documents,
  ) {
    final requests = <BloodRequestModel>[];
    for (final document in documents) {
      try {
        requests.add(BloodRequestModel.fromFirestore(document));
      } catch (error, stackTrace) {
        debugPrint(
          'LifeLink: skipping malformed blood_requests/${document.id}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    return requests;
  }

  /// Fetches a single blood request by ID.
  static Future<BloodRequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _requestsCol.doc(requestId).get();
      if (!doc.exists) return null;
      return BloodRequestModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Creates a new blood request document.
  /// Enforces that non-admin submissions start with status: 'pending' and visibility: 'private'.
  static Future<String?> createRequest({
    required String requesterId,
    String? requesterName,
    String? requesterPhotoUrl,
    required String patientName,
    required String bloodGroup,
    required num units,
    required String hospitalName,
    String hospitalAddress = 'Rajkot, Gujarat',
    required String contactNumber,
    String urgency = 'Normal',
    String createdByRole = 'user',
    bool publishImmediately = false,
  }) async {
    try {
      final docRef = _requestsCol.doc();
      final now = DateTime.now();

      // A request must be created by the currently authenticated, verified
      // requester. Never fall back to a caller-supplied UID.
      final currentAuthUser = AuthService.currentFirebaseUser;
      if (currentAuthUser == null ||
          currentAuthUser.uid != requesterId ||
          !currentAuthUser.emailVerified) {
        debugPrint(
          'LifeLink: createRequest blocked because the authenticated requester is missing, mismatched, or unverified.',
        );
        return null;
      }
      final safeRequesterId = currentAuthUser.uid;

      final safeRequesterName =
          (requesterName != null && requesterName.trim().isNotEmpty)
          ? requesterName.trim()
          : (currentAuthUser?.displayName?.isNotEmpty == true
                ? currentAuthUser!.displayName!
                : 'LifeLink Member');

      final safeRequesterPhoto =
          (requesterPhotoUrl != null && requesterPhotoUrl.trim().isNotEmpty)
          ? requesterPhotoUrl.trim()
          : currentAuthUser?.photoURL;

      final actualRole = createdByRole == 'admin' ? 'admin' : 'user';
      final shouldPublish = actualRole == 'admin' && publishImmediately;

      final request = BloodRequestModel(
        requestId: docRef.id,
        requesterId: safeRequesterId,
        requesterName: safeRequesterName,
        requesterPhotoUrl: safeRequesterPhoto,
        createdByRole: actualRole,
        patientName: patientName.trim(),
        bloodGroup: bloodGroup,
        units: units,
        hospitalName: hospitalName.trim(),
        hospitalAddress: hospitalAddress.trim(),
        contactNumber: contactNumber.trim(),
        urgency: urgency,
        status: shouldPublish ? 'approved' : 'pending',
        visibility: shouldPublish ? 'published' : 'private',
        createdAt: now,
        updatedAt: now,
        feedUpdatedAt: shouldPublish ? now : null,
      );

      await docRef.set(request.toMap());

      // Write the admin audit alert independently from the user notification.
      // Previously both writes shared one try block: the invalid notification
      // type 'request_status' was rejected by Firestore Rules and prevented the
      // admin_logs entry from ever being attempted.
      try {
        await _firestore.collection('admin_logs').add({
          'actorId': safeRequesterId,
          'actorName': safeRequesterName,
          'actorPhotoUrl': safeRequesterPhoto,
          'adminId': safeRequesterId,
          'adminName': safeRequesterName,
          'title': 'New Blood Request Submitted',
          'description':
              '$safeRequesterName submitted a request for $patientName ($bloodGroup, $units Unit(s)) at $hospitalName.',
          'action': 'request_created',
          'targetCollection': 'blood_requests',
          'targetId': docRef.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (error) {
        debugPrint('LifeLink: request-created admin alert failed: $error');
      }

      // This type is explicitly allowed by the supplied Firestore Rules.
      try {
        await _firestore.collection('notifications').add({
          'userId': safeRequesterId,
          'title': 'Blood Request Submitted',
          'message':
              'Your blood request for $patientName ($bloodGroup, $units Units) has been received and is pending admin review.',
          'type': 'request_created',
          'relatedRequestId': docRef.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (error) {
        debugPrint('LifeLink: requester confirmation notification failed: $error');
      }

      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('LifeLink: createRequest failed before completion: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Streams active, published blood requests visible to regular users.
  /// (Strictly filters for visibility == 'published' AND status == 'approved').
  static Stream<List<BloodRequestModel>> streamPublishedRequests({int? limit}) {
    return _requestsCol
        .where('visibility', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
          final list = _parseRequestDocuments(snapshot.docs)
              .where(
                (r) => r.isApproved && !r.isVerified && !r.isDonationCompleted,
              )
              .toList();
          list.sort(
            (a, b) => b.effectiveFeedTime.compareTo(a.effectiveFeedTime),
          );
          if (limit != null && list.length > limit) {
            return list.sublist(0, limit);
          }
          return list;
        });
  }

  /// Streams blood requests created by a specific user.
  static Stream<List<BloodRequestModel>> streamUserRequests(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    return _requestsCol.where('requesterId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final list = _parseRequestDocuments(snapshot.docs);
        list.sort((a, b) => b.effectiveFeedTime.compareTo(a.effectiveFeedTime));
        return list;
      },
    );
  }

  /// Streams unified blood requests for the user's Alerts feed in real time.
  /// Combines published community blood requests and the user's own requests
  /// (including pending, approved, and rejected states).
  static Stream<List<BloodRequestModel>> streamAlertRequests(String userId) {
    if (userId.isEmpty) {
      return streamPublishedRequests();
    }

    late StreamController<List<BloodRequestModel>> controller;
    StreamSubscription<List<BloodRequestModel>>? subPub;
    StreamSubscription<List<BloodRequestModel>>? subUser;

    List<BloodRequestModel> published = [];
    List<BloodRequestModel> userRequests = [];

    void emitMerged() {
      final map = <String, BloodRequestModel>{};
      for (final r in userRequests) {
        map[r.requestId] = r;
      }
      for (final r in published) {
        map[r.requestId] = r;
      }
      final list = map.values.toList();
      list.sort((a, b) => b.effectiveFeedTime.compareTo(a.effectiveFeedTime));
      if (!controller.isClosed) {
        controller.add(list);
      }
    }

    controller = StreamController<List<BloodRequestModel>>.broadcast(
      onListen: () {
        subPub = streamPublishedRequests().listen(
          (data) {
            published = data;
            emitMerged();
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
        );

        subUser = streamUserRequests(userId).listen(
          (data) {
            userRequests = data;
            emitMerged();
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
        );
      },
      onCancel: () {
        subPub?.cancel();
        subUser?.cancel();
      },
    );

    return controller.stream;
  }

  /// Streams all requests for the Admin Panel (pending, approved, rejected).
  static Stream<List<BloodRequestModel>> streamAllRequests() {
    return _requestsCol.snapshots().map((snapshot) {
      final list = _parseRequestDocuments(snapshot.docs);
      list.sort((a, b) => b.effectiveFeedTime.compareTo(a.effectiveFeedTime));
      return list;
    });
  }

  /// Admin approves a blood request and publishes it to the public user feed.
  static Future<bool> adminApproveRequest({
    required String requestId,
    required String adminId,
    String? adminName,
  }) async {
    try {
      final docRef = _requestsCol.doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final requesterId = doc.get('requesterId') as String? ?? '';
      final patientName = doc.get('patientName') as String? ?? 'Patient';
      final bloodGroup = doc.get('bloodGroup') as String? ?? '';
      final effectiveAdminName = adminName ?? 'System Admin';

      final batch = _firestore.batch();

      // 1. Update request status and visibility
      batch.update(docRef, {
        'status': 'approved',
        'visibility': 'published',
        'feedUpdatedAt': FieldValue.serverTimestamp(),
        'adminDecisionBy': adminId,
        'adminDecisionAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Write admin audit log (canonical schema: actorId + actorName)
      final logRef = _firestore.collection('admin_logs').doc();
      batch.set(logRef, {
        'actorId': adminId,
        'actorName': effectiveAdminName,
        'adminId': adminId,
        'adminName': effectiveAdminName,
        'title': 'Blood Request Approved',
        'description':
            'Request for $patientName ($bloodGroup) was approved and published to donors.',
        'action': 'request_approved',
        'targetCollection': 'blood_requests',
        'targetId': requestId,
        'details': {'patientName': patientName, 'bloodGroup': bloodGroup},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Create notification for the requester
      if (requesterId.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': requesterId,
          'title': 'Blood Request Approved',
          'message':
              'Your request for $patientName ($bloodGroup) has been approved and published to donors in Rajkot.',
          'type': 'request_approved',
          'relatedRequestId': requestId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e, stackTrace) {
      debugPrint('LifeLink: adminApproveRequest($requestId) failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Admin rejects a blood request and hides it from the public feed.
  static Future<bool> adminRejectRequest({
    required String requestId,
    required String adminId,
    String? adminName,
    String? reason,
  }) async {
    try {
      final docRef = _requestsCol.doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final requesterId = doc.get('requesterId') as String? ?? '';
      final patientName = doc.get('patientName') as String? ?? 'Patient';
      final bloodGroup = doc.get('bloodGroup') as String? ?? '';
      final effectiveAdminName = adminName ?? 'System Admin';

      final batch = _firestore.batch();

      // 1. Update request status to rejected and visibility to private
      batch.update(docRef, {
        'status': 'rejected',
        'visibility': 'private',
        'adminDecisionBy': adminId,
        'adminDecisionAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Write admin audit log (canonical schema: actorId + actorName)
      final logRef = _firestore.collection('admin_logs').doc();
      batch.set(logRef, {
        'actorId': adminId,
        'actorName': effectiveAdminName,
        'adminId': adminId,
        'adminName': effectiveAdminName,
        'title': 'Blood Request Rejected',
        'description':
            'Request for $patientName was rejected. Reason: ${reason ?? "Administrative review"}',
        'action': 'request_rejected',
        'targetCollection': 'blood_requests',
        'targetId': requestId,
        'details': {
          'reason': reason ?? 'Administrative review',
          'patientName': patientName,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Notify the requester with explicit rejection message
      if (requesterId.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        final reasonSuffix = (reason != null && reason.trim().isNotEmpty)
            ? ' Reason: ${reason.trim()}'
            : '';
        batch.set(notifRef, {
          'userId': requesterId,
          'title': 'Blood Request Rejected',
          'message':
              'Your blood request was rejected by the admin.$reasonSuffix (Patient: $patientName, $bloodGroup)',
          'type': 'request_rejected',
          'relatedRequestId': requestId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e, stackTrace) {
      debugPrint('LifeLink: adminRejectRequest($requestId) failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Republishes a previously rejected blood request so eligible donors can respond.
  /// Preserves previous rejection record in admin_logs and notifies requester.
  static Future<bool> adminRepublishRequest({
    required String requestId,
    required String adminId,
    String? adminName,
  }) async {
    try {
      final docRef = _requestsCol.doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final requesterId = doc.get('requesterId') as String? ?? '';
      final patientName = doc.get('patientName') as String? ?? 'Patient';
      final bloodGroup = doc.get('bloodGroup') as String? ?? '';
      final previousReason = doc.get('rejectionReason') as String?;
      final effectiveAdminName = adminName ?? 'System Admin';

      final batch = _firestore.batch();

      // 1. Update request status to approved and visibility to published
      batch.update(docRef, {
        'status': 'approved',
        'visibility': 'published',
        'isRepublished': true,
        'republishedAt': FieldValue.serverTimestamp(),
        'feedUpdatedAt': FieldValue.serverTimestamp(),
        'adminDecisionBy': adminId,
        'adminDecisionAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Write admin audit log (canonical schema: actorId + actorName)
      final logRef = _firestore.collection('admin_logs').doc();
      batch.set(logRef, {
        'actorId': adminId,
        'actorName': effectiveAdminName,
        'adminId': adminId,
        'adminName': effectiveAdminName,
        'title': 'Blood Request Republished',
        'description':
            'Previously rejected request for $patientName ($bloodGroup) was republished to donors.',
        'action': 'request_republished',
        'targetCollection': 'blood_requests',
        'targetId': requestId,
        'details': {
          'patientName': patientName,
          'bloodGroup': bloodGroup,
          'previousRejectionReason': previousReason,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Notify the requester
      if (requesterId.isNotEmpty) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': requesterId,
          'title': 'Blood Request Republished',
          'message':
              'Your blood request for $patientName ($bloodGroup) has been republished by the administrator and is now live for donors.',
          'type': 'request_republished',
          'relatedRequestId': requestId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e, stackTrace) {
      debugPrint('LifeLink: adminRepublishRequest($requestId) failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Donor accepts a published blood request using an atomic Firestore transaction.
  /// Enforces single-confirmed donor, blood compatibility, and role checks.
  static Future<Map<String, dynamic>> acceptRequest({
    required String requestId,
    required DonorModel donorProfile,
    UserModel? donorUser,
  }) async {
    try {
      if (donorProfile.isAdmin || (donorUser != null && donorUser.isAdmin)) {
        return {
          'success': false,
          'error': 'Administrators cannot accept blood requests as donors.',
        };
      }
      if (!donorProfile.isAvailable) {
        return {
          'success': false,
          'error':
              'Your profile is currently marked as unavailable for donations.',
        };
      }
      if (!donorProfile.isReady) {
        return {
          'success': false,
          'error':
              'Your eligibility status is ${donorProfile.eligibilityStatus}. You must be READY to donate.',
        };
      }

      final docRef = _requestsCol.doc(requestId);

      return await _firestore.runTransaction((tx) async {
        final reqDoc = await tx.get(docRef);
        if (!reqDoc.exists) {
          return {'success': false, 'error': 'Blood request not found.'};
        }

        final data = reqDoc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'pending';
        final visibility = data['visibility'] as String? ?? 'private';
        final requesterId = data['requesterId'] as String? ?? '';
        final existingDonorId = data['donorId'] as String?;
        final requestBloodGroup = data['bloodGroup'] as String? ?? '';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final hospitalName = data['hospitalName'] as String? ?? 'the hospital';

        if (status != 'approved' || visibility != 'published') {
          return {
            'success': false,
            'error': 'This request is no longer active.',
          };
        }

        if (existingDonorId != null && existingDonorId.isNotEmpty) {
          return {
            'success': false,
            'error': 'This request has already been accepted by another donor.',
          };
        }

        final donorId = donorUser?.uid ?? donorProfile.userId;

        if (requesterId == donorId) {
          return {
            'success': false,
            'error': 'You cannot accept your own blood request.',
          };
        }

        if (!DonorModel.isBloodCompatible(
          donorProfile.bloodGroup,
          requestBloodGroup,
        )) {
          return {
            'success': false,
            'error':
                'Your blood group (${donorProfile.bloodGroup}) is incompatible with recipient group ($requestBloodGroup).',
          };
        }

        final photo =
            donorUser?.profileImageUrl ?? donorProfile.profileImageUrl;

        // Assign confirmed donor to request
        tx.update(docRef, {
          'donorId': donorId,
          'donorName': donorProfile.fullName,
          'donorPhotoUrl': photo,
          'donorPhone': donorProfile.phoneNumber,
          'donorBloodGroup': donorProfile.bloodGroup,
          'donorCity': donorProfile.city,
          'donationStatus': 'donor_accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Notify requester
        final notifRef = _firestore.collection('notifications').doc();
        tx.set(notifRef, {
          'userId': requesterId,
          'title': 'Blood Request Accepted',
          'message':
              'Your blood request for $patientName ($requestBloodGroup) was accepted by ${donorProfile.fullName} (${donorProfile.bloodGroup}). Contact: ${donorProfile.phoneNumber}.',
          'type': 'donor_accepted',
          'relatedRequestId': requestId,
          'actorName': donorProfile.fullName,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Notify accepting donor
        final donorNotifRef = _firestore.collection('notifications').doc();
        tx.set(donorNotifRef, {
          'userId': donorId,
          'title': 'Donation Acceptance Registered',
          'message':
              'You accepted the blood request for $patientName ($requestBloodGroup) at $hospitalName. Please coordinate with the hospital/requester.',
          'type': 'donor_accepted',
          'relatedRequestId': requestId,
          'actorName': 'LifeLink',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Audit log for admin oversight (canonical schema: actorId + actorName)
        final logRef = _firestore.collection('admin_logs').doc();
        tx.set(logRef, {
          'actorId': donorId,
          'actorName': donorProfile.fullName,
          'actorPhotoUrl': photo,
          'adminId': donorId,
          'adminName': donorProfile.fullName,
          'title': 'Donor Accepted Blood Request',
          'description':
              'Donor ${donorProfile.fullName} (${donorProfile.bloodGroup}) accepted request for $patientName ($requestBloodGroup).',
          'action': 'request_accepted',
          'targetCollection': 'blood_requests',
          'targetId': requestId,
          'details': {
            'donorName': donorProfile.fullName,
            'donorId': donorId,
            'patientName': patientName,
            'bloodGroup': requestBloodGroup,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BloodRequestService.acceptRequest] Denied or failed: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Releases or reopens an accepted blood request.
  /// Allowed strictly for the original requester before donation verification.
  /// Clears assigned donor, notifies previous donor, and preserves audit record in admin_logs.
  static Future<Map<String, dynamic>> releaseDonorAssignment({
    required String requestId,
    required String actorId,
    String? actorName,
    String? reason,
    bool isAdmin = false,
  }) async {
    String currentStage = 'initialization';
    try {
      final reqRef = _requestsCol.doc(requestId);

      return await _firestore.runTransaction((tx) async {
        currentStage = 'request_read';
        final reqDoc = await tx.get(reqRef);
        if (!reqDoc.exists) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'Blood request not found.',
          };
        }

        final data = reqDoc.data() as Map<String, dynamic>;
        final actualRequesterId = data['requesterId'] as String? ?? '';
        final previousDonorId = data['donorId'] as String?;
        final previousDonorName = data['donorName'] as String? ?? 'Donor';
        final requesterName = data['requesterName'] as String? ?? 'Requester';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final donationStatus = data['donationStatus'] as String?;

        // 1. Authoritative verification of requester ownership (strictly requester-only)
        currentStage = 'authorization_check';
        if (actualRequesterId != actorId) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error':
                'Only the original requester can release the assigned donor.',
          };
        }

        // 2. Only allow when a donor is assigned and in donor_accepted state
        currentStage = 'eligibility_check';
        if (previousDonorId == null || previousDonorId.isEmpty) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'No donor is currently assigned to this request.',
          };
        }

        if (donationStatus != 'donor_accepted') {
          return {
            'success': false,
            'failedStage': currentStage,
            'error':
                'Donor can only be released when the request is in "donor_accepted" status.',
          };
        }

        // 3. Clear current donor assignment, reset state, update feed ordering, preserve createdAt
        currentStage = 'request_update';
        tx.update(reqRef, {
          'donorId': FieldValue.delete(),
          'donorName': FieldValue.delete(),
          'donorPhotoUrl': FieldValue.delete(),
          'donorPhone': FieldValue.delete(),
          'donorBloodGroup': FieldValue.delete(),
          'donorCity': FieldValue.delete(),
          'acceptedAt': FieldValue.delete(),
          'donationStatus': 'waiting_donor',
          'confirmedUnits': FieldValue.delete(),
          'confirmedAt': FieldValue.delete(),
          'completionNotes': FieldValue.delete(),
          'notCompletedReason': FieldValue.delete(),
          'notCompletedAt': FieldValue.delete(),
          'lastReleasedDonorId': previousDonorId,
          'lastReleasedDonorName': previousDonorName,
          'lastReleasedReason': reason,
          'lastReleasedAt': FieldValue.serverTimestamp(),
          'status': 'approved',
          'visibility': 'published',
          'reopenedAt': FieldValue.serverTimestamp(),
          'feedUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final effectiveActorName = actorName ?? requesterName;

        // 4. Notify previous donor
        currentStage = 'notification_create';
        final notifRef = _firestore.collection('notifications').doc();
        final reasonSuffix = (reason != null && reason.trim().isNotEmpty)
            ? ' Reason: ${reason.trim()}'
            : '';
        tx.set(notifRef, {
          'userId': previousDonorId,
          'title': 'Request Assignment Released',
          'message':
              'Your assignment for $patientName has been released by $effectiveActorName.$reasonSuffix The request has been reopened.',
          'type': 'donor_released',
          'relatedRequestId': requestId,
          'actorName': effectiveActorName,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 5. Admin audit log (canonical schema: actorId + actorName)
        currentStage = 'audit_log_create';
        final logRef = _firestore.collection('admin_logs').doc();
        tx.set(logRef, {
          'actorId': actorId,
          'actorName': effectiveActorName,
          'adminId': actorId,
          'adminName': effectiveActorName,
          'title': 'Donor Assignment Released',
          'description':
              'Assignment for $previousDonorName on request for $patientName was released by $effectiveActorName.$reasonSuffix',
          'action': 'donor_released',
          'targetCollection': 'blood_requests',
          'targetId': requestId,
          'details': {
            'previousDonorId': previousDonorId,
            'previousDonorName': previousDonorName,
            'patientName': patientName,
            'reason': reason,
            'releasedBy': actorId,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      });
    } catch (e) {
      return {
        'success': false,
        'failedStage': currentStage,
        'error': e.toString(),
      };
    }
  }

  /// Requester confirms that the accepted donor completed the donation.
  /// Creates one donation record in 'pending_verification' status.
  /// (Does NOT increment donor totals until an administrator verifies the record).
  static Future<Map<String, dynamic>> confirmDonationCompleted({
    required String requestId,
    required String requesterId,
    num? confirmedUnits,
    num? unitsDonated,
    String? notes,
  }) async {
    final actualUnits = confirmedUnits ?? unitsDonated;
    if (actualUnits == null) {
      return {
        'success': false,
        'failedStage': 'validation',
        'error': 'Please enter the number of units donated.',
      };
    }
    if (actualUnits <= 0) {
      return {
        'success': false,
        'failedStage': 'validation',
        'error': 'Donation units must be greater than zero.',
      };
    }
    if (actualUnits > 10) {
      return {
        'success': false,
        'failedStage': 'validation',
        'error': 'Donation units cannot exceed permitted maximum (10 units).',
      };
    }

    String currentStage = 'initialization';
    try {
      final reqRef = _requestsCol.doc(requestId);
      final donationDocId = 'donation_$requestId';
      final donationRef = _firestore.collection('donations').doc(donationDocId);

      return await _firestore.runTransaction((tx) async {
        // Read parent blood request doc inside transaction
        currentStage = 'request_read';
        final reqDoc = await tx.get(reqRef);
        if (!reqDoc.exists) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'Blood request not found.',
          };
        }

        final data = reqDoc.data() as Map<String, dynamic>;
        final actualRequesterId = data['requesterId'] as String? ?? '';
        final donorId = data['donorId'] as String?;
        final donorName = data['donorName'] as String? ?? 'Donor';
        final requesterName = data['requesterName'] as String? ?? 'Requester';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final hospitalName =
            data['hospitalName'] as String? ?? 'Civil Hospital';
        final hospitalAddress =
            data['hospitalAddress'] as String? ?? 'Rajkot, Gujarat';
        final bloodGroup = data['bloodGroup'] as String? ?? 'O+';
        final donationStatus = data['donationStatus'] as String?;
        final requestUnits =
            (data['units'] ?? data['unitsRequired']) as num? ?? 10;

        currentStage = 'authorization_check';
        if (actualRequesterId != requesterId) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'Only the requester can confirm donation completion.',
          };
        }

        currentStage = 'eligibility_check';
        if (donorId == null || donorId.isEmpty) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'No donor is assigned to this request.',
          };
        }

        if (donorId == requesterId) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'Requester cannot be the assigned donor.',
          };
        }

        if (donationStatus != 'donor_accepted') {
          return {
            'success': false,
            'failedStage': currentStage,
            'error':
                'Donation can only be confirmed when request is in "donor_accepted" status.',
          };
        }

        if (actualUnits > requestUnits) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error':
                'Confirmed units ($actualUnits) cannot exceed requested quantity ($requestUnits).',
          };
        }

        // 1. Update Blood Request document to pending_verification (locking assigned donor)
        currentStage = 'request_update';
        tx.update(reqRef, {
          'donationStatus': 'pending_verification',
          'confirmedUnits': actualUnits,
          'confirmedAt': FieldValue.serverTimestamp(),
          'completionNotes': (notes != null && notes.trim().isNotEmpty)
              ? notes.trim()
              : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Set deterministic donation record in pending_verification status (prevents duplicates)
        currentStage = 'donation_create';
        tx.set(donationRef, {
          'donationId': donationDocId,
          'donorId': donorId,
          'donorName': donorName,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'patientName': patientName,
          'bloodRequestId': requestId,
          'hospitalName': hospitalName,
          'hospitalAddress': hospitalAddress,
          'bloodGroup': bloodGroup,
          'unitsDonated': actualUnits,
          'status': 'pending_verification', // Awaiting admin verification
          'confirmedByRequester': true,
          'donationDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. Notify donor that donation was confirmed and is awaiting admin verification
        currentStage = 'notification_create';
        final notifRef = _firestore.collection('notifications').doc();
        tx.set(notifRef, {
          'userId': donorId,
          'title': 'Donation Awaiting Verification',
          'message':
              'Requester $requesterName confirmed your donation of $actualUnits unit(s) for $patientName. The donation is awaiting administrative verification.',
          'type': 'donation_confirmed',
          'relatedRequestId': requestId,
          'actorName': requesterName,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. Admin audit log (canonical schema: actorId + actorName)
        currentStage = 'audit_log_create';
        final logRef = _firestore.collection('admin_logs').doc();
        tx.set(logRef, {
          'actorId': requesterId,
          'actorName': requesterName,
          'adminId': requesterId,
          'adminName': requesterName,
          'title': 'Donation Pending Verification',
          'description':
              'Requester $requesterName confirmed completed donation of $actualUnits unit(s) by $donorName ($bloodGroup) for $patientName. Awaiting admin verification.',
          'action': 'donation_pending_verification',
          'targetCollection': 'donations',
          'targetId': donationDocId,
          'details': {
            'donorName': donorName,
            'donorId': donorId,
            'unitsDonated': actualUnits,
            'patientName': patientName,
            'bloodRequestId': requestId,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      });
    } catch (e) {
      return {
        'success': false,
        'failedStage': currentStage,
        'error': e.toString(),
      };
    }
  }

  /// Requester reports that the scheduled donation did not occur.
  /// Reopens the request for other donors and clears assigned donor.
  static Future<Map<String, dynamic>> reportDonationDidNotHappen({
    required String requestId,
    required String requesterId,
    String? reason,
  }) async {
    String currentStage = 'initialization';
    try {
      final reqRef = _requestsCol.doc(requestId);

      return await _firestore.runTransaction((tx) async {
        currentStage = 'request_read';
        final reqDoc = await tx.get(reqRef);
        if (!reqDoc.exists) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'Blood request not found.',
          };
        }

        final data = reqDoc.data() as Map<String, dynamic>;
        final actualRequesterId = data['requesterId'] as String? ?? '';
        final donorId = data['donorId'] as String?;
        final donorName = data['donorName'] as String? ?? 'Donor';
        final requesterName = data['requesterName'] as String? ?? 'Requester';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final donationStatus = data['donationStatus'] as String?;

        currentStage = 'authorization_check';
        if (actualRequesterId != requesterId) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'Only the requester can report on donation status.',
          };
        }

        currentStage = 'eligibility_check';
        if (donorId == null || donorId.isEmpty) {
          return {
            'success': false,
            'failedStage': currentStage,
            'error': 'No donor was assigned to this request.',
          };
        }

        if (donationStatus != 'donor_accepted') {
          return {
            'success': false,
            'failedStage': currentStage,
            'error':
                'Reporting donation did not happen is only allowed when request is in "donor_accepted" status.',
          };
        }

        // Atomically clear active donor assignment, reset to waiting_donor, update feed freshness
        currentStage = 'request_update';
        tx.update(reqRef, {
          'donorId': FieldValue.delete(),
          'donorName': FieldValue.delete(),
          'donorPhotoUrl': FieldValue.delete(),
          'donorPhone': FieldValue.delete(),
          'donorBloodGroup': FieldValue.delete(),
          'donorCity': FieldValue.delete(),
          'acceptedAt': FieldValue.delete(),
          'donationStatus': 'waiting_donor',
          'confirmedUnits': FieldValue.delete(),
          'confirmedAt': FieldValue.delete(),
          'completionNotes': FieldValue.delete(),
          'notCompletedReason': reason,
          'notCompletedAt': FieldValue.serverTimestamp(),
          'lastReleasedDonorId': donorId,
          'lastReleasedDonorName': donorName,
          'lastReleasedReason': reason,
          'lastReleasedAt': FieldValue.serverTimestamp(),
          'lastNotCompletedDonorId': donorId,
          'lastNotCompletedDonorName': donorName,
          'lastNotCompletedReason': reason,
          'lastNotCompletedAt': FieldValue.serverTimestamp(),
          'lastUnsuccessfulAttempt': {
            'donorId': donorId,
            'donorName': donorName,
            'reason': reason,
          },
          'unsuccessfulAttemptReason': reason,
          'status': 'approved',
          'visibility': 'published',
          'reopenedAt': FieldValue.serverTimestamp(),
          'feedUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final reasonSuffix = (reason != null && reason.trim().isNotEmpty)
            ? ' Reason: ${reason.trim()}'
            : '';

        // Notify previous donor
        currentStage = 'notification_create';
        final notifRef = _firestore.collection('notifications').doc();
        tx.set(notifRef, {
          'userId': donorId,
          'title': 'Donation Not Completed',
          'message':
              'Requester $requesterName reported that the scheduled blood donation for $patientName did not take place.$reasonSuffix The request has been reopened.',
          'type': 'donation_not_completed',
          'relatedRequestId': requestId,
          'actorName': requesterName,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Admin alert / audit log (canonical schema: actorId + actorName)
        currentStage = 'audit_log_create';
        final logRef = _firestore.collection('admin_logs').doc();
        tx.set(logRef, {
          'actorId': requesterId,
          'actorName': requesterName,
          'adminId': requesterId,
          'adminName': requesterName,
          'title': 'Donation Reported Not Completed',
          'description':
              'Requester $requesterName reported donation by $donorName did not occur.$reasonSuffix The request was reopened for donors.',
          'action': 'donation_not_completed',
          'targetCollection': 'blood_requests',
          'targetId': requestId,
          'details': {
            'donorName': donorName,
            'donorId': donorId,
            'requesterName': requesterName,
            'requesterId': requesterId,
            'patientName': patientName,
            'reason': reason,
            'requestId': requestId,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      });
    } catch (e) {
      return {
        'success': false,
        'failedStage': currentStage,
        'error': e.toString(),
      };
    }
  }

  /// Withdraws a published request (admin or owner).
  static Future<bool> withdrawRequest({
    required String requestId,
    required String userId,
    bool isAdmin = false,
  }) async {
    try {
      await _requestsCol.doc(requestId).update({
        'status': 'cancelled',
        'visibility': 'private',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
