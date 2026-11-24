import 'package:cloud_firestore/cloud_firestore.dart';
import '../Manob/donation_model.dart';
import '../Manob/firebase_service.dart';
import '../Pratik/admin_service.dart';

class DonationService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final CollectionReference _donationsCol = _firestore.collection(
    'donations',
  );

  /// Streams donation history records for a specific donor in real time.
  /// Sorts in memory to avoid requiring complex composite indexes.
  static Stream<List<DonationModel>> streamDonationsForDonor(String donorId) {
    if (donorId.isEmpty) return Stream.value([]);
    return _donationsCol.where('donorId', isEqualTo: donorId).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => DonationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final dateA = a.donationDate ?? a.createdAt;
        final dateB = b.donationDate ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Streams all donation records for the Admin Panel.
  static Stream<List<DonationModel>> streamAllDonations() {
    return _donationsCol.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DonationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final dateA = a.donationDate ?? a.createdAt;
        final dateB = b.donationDate ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Streams donations awaiting administrator verification.
  static Stream<List<DonationModel>> streamPendingDonations() {
    return _donationsCol.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DonationModel.fromFirestore(doc))
          .where((d) => d.isPendingVerification)
          .toList();
      list.sort((a, b) {
        final dateA = a.donationDate ?? a.createdAt;
        final dateB = b.donationDate ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Streams verified donations only.
  static Stream<List<DonationModel>> streamVerifiedDonations() {
    return _donationsCol.where('status', isEqualTo: 'verified').snapshots().map(
      (snapshot) {
        final list = snapshot.docs
            .map((doc) => DonationModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) {
          final dateA = a.donationDate ?? a.createdAt;
          final dateB = b.donationDate ?? b.createdAt;
          return dateB.compareTo(dateA);
        });
        return list;
      },
    );
  }

  /// Administrator verifies a completed blood donation.
  /// Executes inside an atomic transaction:
  /// - Idempotent: checks status is not already 'verified'.
  /// - Units donated remain IMMUTABLE during verification (no manual alteration).
  /// - Increments donor's totalDonationCount (+1) and totalUnitsDonated (+units).
  /// - Updates lastDonationAt and sets donor eligibility to COOLDOWN.
  /// - Notifies both donor and requester.
  static Future<Map<String, dynamic>> adminVerifyDonation({
    required String donationId,
    required String adminId,
    String? adminName,
  }) async {
    try {
      final donationRef = _donationsCol.doc(donationId);

      return await _firestore.runTransaction((tx) async {
        final docSnap = await tx.get(donationRef);
        if (!docSnap.exists) {
          return {'success': false, 'error': 'Donation record not found.'};
        }

        final data = docSnap.data() as Map<String, dynamic>;
        final currentStatus = data['status'] as String? ?? '';
        final donorId = data['donorId'] as String? ?? '';
        final donorName = data['donorName'] as String? ?? 'Donor';
        final requesterId = data['requesterId'] as String? ?? '';
        final requesterName = data['requesterName'] as String? ?? 'Requester';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final bloodGroup = data['bloodGroup'] as String? ?? '';
        final units = data['unitsDonated'] as num? ?? 1;
        final bloodRequestId = data['bloodRequestId'] as String?;

        // Idempotency: do not double-count if already verified
        if (currentStatus == 'verified') {
          return {
            'success': true,
            'message': 'This donation is already verified.',
          };
        }

        final effectiveAdminName = adminName ?? 'System Admin';

        // 1. Update Donation record to verified
        tx.update(donationRef, {
          'status': 'verified',
          'verifiedBy': adminId,
          'verifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Atomically update donor statistics & recovery cooldown
        if (donorId.isNotEmpty) {
          final donorRef = _firestore.collection('donor_profiles').doc(donorId);
          tx.update(donorRef, {
            'totalDonationCount': FieldValue.increment(1),
            'totalUnitsDonated': FieldValue.increment(units),
            'lastDonationAt': FieldValue.serverTimestamp(),
            'lastVerifiedDonationId': donationId,
            'eligibilityStatus': 'COOLDOWN',
            'isAvailable': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Update associated blood request status if present to fulfilled/closed
        if (bloodRequestId != null && bloodRequestId.isNotEmpty) {
          final reqRef = _firestore
              .collection('blood_requests')
              .doc(bloodRequestId);
          tx.update(reqRef, {
            'status': 'fulfilled',
            'donationStatus': 'verified',
            'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 4. Notify donor
        if (donorId.isNotEmpty) {
          final notifRef = _firestore.collection('notifications').doc();
          tx.set(notifRef, {
            'userId': donorId,
            'title': 'Donation Verified!',
            'message':
                'Your donation of $units unit(s) for $patientName ($bloodGroup), requested by $requesterName, was verified by the administrator. Thank you for your life-saving support!',
            'type': 'donation_verified',
            'relatedRequestId': bloodRequestId ?? donationId,
            'actorName': effectiveAdminName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 5. Notify requester
        if (requesterId.isNotEmpty) {
          final reqNotifRef = _firestore.collection('notifications').doc();
          tx.set(reqNotifRef, {
            'userId': requesterId,
            'title': 'Donation Verified by Admin',
            'message':
                'The completed donation of $units unit(s) by $donorName for $patientName has been verified by the administrator.',
            'type': 'donation_verified',
            'relatedRequestId': bloodRequestId ?? donationId,
            'actorName': effectiveAdminName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 6. Admin audit log (canonical schema: actorId + actorName)
        final logRef = _firestore.collection('admin_logs').doc();
        tx.set(logRef, {
          'actorId': adminId,
          'actorName': effectiveAdminName,
          'adminId': adminId,
          'adminName': effectiveAdminName,
          'title': 'Blood Donation Verified',
          'description':
              'Verified donation of $units unit(s) donated by $donorName ($bloodGroup) for $patientName.',
          'action': 'donation_verified',
          'targetCollection': 'donations',
          'targetId': donationId,
          'details': {
            'donorName': donorName,
            'donorId': donorId,
            'requesterId': requesterId,
            'units': units,
            'patientName': patientName,
            'bloodRequestId': bloodRequestId,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      });
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Administrator rejects or flags an unverified donation record.
  /// Does NOT increment donor statistics.
  static Future<Map<String, dynamic>> adminRejectDonation({
    required String donationId,
    required String adminId,
    String? reason,
    String? adminName,
  }) async {
    try {
      final donationRef = _donationsCol.doc(donationId);

      return await _firestore.runTransaction((tx) async {
        final docSnap = await tx.get(donationRef);
        if (!docSnap.exists) {
          return {'success': false, 'error': 'Donation record not found.'};
        }

        final data = docSnap.data() as Map<String, dynamic>;
        final donorId = data['donorId'] as String? ?? '';
        final donorName = data['donorName'] as String? ?? 'Donor';
        final requesterId = data['requesterId'] as String? ?? '';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final bloodRequestId = data['bloodRequestId'] as String?;
        final effectiveAdminName = adminName ?? 'System Admin';

        // 1. Update Donation record to rejected
        tx.update(donationRef, {
          'status': 'rejected',
          'rejectionReason': reason ?? 'Administrative review',
          'verifiedBy': adminId,
          'verifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Update associated request status if present
        if (bloodRequestId != null && bloodRequestId.isNotEmpty) {
          final reqRef = _firestore
              .collection('blood_requests')
              .doc(bloodRequestId);
          tx.update(reqRef, {
            'donationStatus': 'donation_rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final reasonSuffix = (reason != null && reason.trim().isNotEmpty)
            ? ' Reason: ${reason.trim()}'
            : '';

        // 3. Notify donor
        if (donorId.isNotEmpty) {
          final notifRef = _firestore.collection('notifications').doc();
          tx.set(notifRef, {
            'userId': donorId,
            'title': 'Donation Record Rejected',
            'message':
                'Your recorded donation for $patientName could not be verified by the administrator.$reasonSuffix',
            'type': 'donation_rejected',
            'relatedRequestId': bloodRequestId ?? donationId,
            'actorName': effectiveAdminName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 4. Notify requester
        if (requesterId.isNotEmpty) {
          final reqNotifRef = _firestore.collection('notifications').doc();
          tx.set(reqNotifRef, {
            'userId': requesterId,
            'title': 'Donation Record Rejected',
            'message':
                'The reported donation by $donorName for $patientName could not be verified.$reasonSuffix',
            'type': 'donation_rejected',
            'relatedRequestId': bloodRequestId ?? donationId,
            'actorName': effectiveAdminName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 5. Admin audit log (canonical schema: actorId + actorName)
        final logRef = _firestore.collection('admin_logs').doc();
        tx.set(logRef, {
          'actorId': adminId,
          'actorName': effectiveAdminName,
          'adminId': adminId,
          'adminName': effectiveAdminName,
          'title': 'Donation Record Rejected',
          'description':
              'Donation for $patientName was rejected by $effectiveAdminName.$reasonSuffix',
          'action': 'donation_rejected',
          'targetCollection': 'donations',
          'targetId': donationId,
          'details': {
            'donorName': donorName,
            'donorId': donorId,
            'reason': reason,
            'bloodRequestId': bloodRequestId,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      });
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Administrator resolves a request following donation rejection.
  /// If [reopenToCommunity] is true: clears assigned donor, resets to 'waiting_donor',
  /// updates feedUpdatedAt, keeping status approved and visibility published.
  /// If [reopenToCommunity] is false: closes the request (status: 'cancelled', visibility: 'private').
  static Future<Map<String, dynamic>> adminResolveRejectedRequest({
    required String requestId,
    required String adminId,
    required bool reopenToCommunity,
    String? adminName,
  }) async {
    try {
      final reqRef = _firestore.collection('blood_requests').doc(requestId);
      return await _firestore.runTransaction((tx) async {
        final doc = await tx.get(reqRef);
        if (!doc.exists) {
          return {'success': false, 'error': 'Blood request not found.'};
        }

        final effectiveAdminName = adminName ?? 'System Admin';

        if (reopenToCommunity) {
          tx.update(reqRef, {
            'donorId': FieldValue.delete(),
            'donorName': FieldValue.delete(),
            'donorPhotoUrl': FieldValue.delete(),
            'donorPhone': FieldValue.delete(),
            'donorBloodGroup': FieldValue.delete(),
            'donorCity': FieldValue.delete(),
            'acceptedAt': FieldValue.delete(),
            'donationStatus': 'waiting_donor',
            'status': 'approved',
            'visibility': 'published',
            'reopenedAt': FieldValue.serverTimestamp(),
            'feedUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(reqRef, {
            'status': 'cancelled',
            'visibility': 'private',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final logRef = _firestore.collection('admin_logs').doc();
        tx.set(logRef, {
          'actorId': adminId,
          'actorName': effectiveAdminName,
          'adminId': adminId,
          'adminName': effectiveAdminName,
          'title': reopenToCommunity
              ? 'Request Reopened by Admin'
              : 'Request Closed by Admin',
          'description': reopenToCommunity
              ? 'Request was reopened to community donors by $effectiveAdminName.'
              : 'Request was closed by $effectiveAdminName.',
          'action': reopenToCommunity
              ? 'request_republished'
              : 'request_rejected',
          'targetCollection': 'blood_requests',
          'targetId': requestId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      });
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Authoritative aggregate calculation:
  /// Note: Under hardened Firestore security rules, arbitrary client-side aggregate writes
  /// are strictly prohibited. Totals may only increment atomically upon administrator verification
  /// of a legitimate donation document.
  static Future<void> recalculateDonorAggregates(String donorId) async {
    // Client-side aggregate rewrites are prohibited by Firestore security rules.
  }

  /// Deletes an unverified donation record.
  /// (Verified donation records are protected and cannot be deleted via generic delete).
  static Future<bool> deleteDonation({
    required String donationId,
    String? adminId,
  }) async {
    try {
      final docRef = _donationsCol.doc(donationId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final currentStatus = doc.get('status') as String? ?? '';
      // Verified donations are protected from arbitrary deletion
      if (currentStatus == 'verified') {
        return false;
      }

      final donorId = doc.get('donorId') as String? ?? '';

      await docRef.delete();

      if (adminId != null) {
        await AdminService.logAction(
          actorId: adminId,
          adminId: adminId,
          action: 'donation_deleted',
          targetCollection: 'donations',
          targetId: donationId,
          details: {'donorId': donorId, 'previousStatus': currentStatus},
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
