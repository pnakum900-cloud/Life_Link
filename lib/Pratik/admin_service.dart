import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../Manob/firebase_service.dart';
import 'admin_log_model.dart';

class AdminDashboardStats {
  final int totalUsers; // Active regular users
  final int totalDonors; // Regular donors
  final int availableDonors; // Regular donors eligible and available
  final int pendingRequests; // Requests pending admin review
  final int approvedRequests; // Approved requests
  final int rejectedRequests; // Rejected requests
  final int verifiedDonations; // Admin-verified donations
  final num totalVerifiedUnits; // Total verified units

  AdminDashboardStats({
    this.totalUsers = 0,
    this.totalDonors = 0,
    this.availableDonors = 0,
    this.pendingRequests = 0,
    this.approvedRequests = 0,
    this.rejectedRequests = 0,
    this.verifiedDonations = 0,
    this.totalVerifiedUnits = 0,
  });
}

/// Result of administrative user and cascade data deletion.
class UserDeletionResult {
  final bool success;
  final String? failedStage;
  final String? error;
  final int totalDeletedDocs;
  final String targetUid;
  final String targetEmail;
  final bool authAccountPendingManualDeletion;

  UserDeletionResult({
    required this.success,
    this.failedStage,
    this.error,
    this.totalDeletedDocs = 0,
    required this.targetUid,
    required this.targetEmail,
    this.authAccountPendingManualDeletion = true,
  });
}

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  // -------------------------------------------------------------
  // DASHBOARD STATISTICS (Real-time and Authoritative)
  // -------------------------------------------------------------

  /// Fetches authoritative dashboard statistics from Cloud Firestore.
  /// - Excludes administrators from active users and donor totals.
  /// - Sums units and verified count strictly from 'verified' donation records.
  static Future<AdminDashboardStats> fetchDashboardStats() async {
    try {
      // 1. Active Users (Regular users with accountStatus == 'active', excluding admins)
      final usersSnap = await _firestore.collection('users').get();
      final activeRegularUsers = usersSnap.docs.where((doc) {
        final data = doc.data();
        final role = (data['role'] as String? ?? 'user').toLowerCase();
        final status = (data['accountStatus'] as String? ?? 'active')
            .toLowerCase();
        return role != 'admin' && status == 'active';
      }).length;

      // 2. Total Donors & Available Donors (Regular donors, excluding admins)
      final donorsSnap = await _firestore.collection('donor_profiles').get();
      final eligibleDonors = donorsSnap.docs.where((d) {
        final data = d.data();
        final role = (data['role'] as String? ?? 'user').toLowerCase();
        return role != 'admin';
      }).toList();

      final totalDonorsCount = eligibleDonors.length;
      final availableDonorsCount = eligibleDonors.where((d) {
        final data = d.data();
        final isAvailable = data['isAvailable'] == true;
        final eligibility = (data['eligibilityStatus'] as String? ?? 'READY')
            .toUpperCase();
        return isAvailable && eligibility == 'READY';
      }).length;

      // 3. Blood Requests (Pending, Approved, Rejected)
      final pendingReqSnap = await _firestore
          .collection('blood_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      final approvedReqSnap = await _firestore
          .collection('blood_requests')
          .where('status', isEqualTo: 'approved')
          .get();
      final rejectedReqSnap = await _firestore
          .collection('blood_requests')
          .where('status', isEqualTo: 'rejected')
          .get();

      // 4. Verified Donations & Verified Units (strictly status == 'verified')
      final verifiedDonationsSnap = await _firestore
          .collection('donations')
          .where('status', isEqualTo: 'verified')
          .get();

      num totalUnits = 0;
      for (final doc in verifiedDonationsSnap.docs) {
        totalUnits += (doc.get('unitsDonated') as num? ?? 0);
      }

      return AdminDashboardStats(
        totalUsers: activeRegularUsers,
        totalDonors: totalDonorsCount,
        availableDonors: availableDonorsCount,
        pendingRequests: pendingReqSnap.docs.length,
        approvedRequests: approvedReqSnap.docs.length,
        rejectedRequests: rejectedReqSnap.docs.length,
        verifiedDonations: verifiedDonationsSnap.docs.length,
        totalVerifiedUnits: totalUnits,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Streams dashboard statistics in real time responding to updates in:
  /// - users
  /// - donor_profiles
  /// - blood_requests
  /// - donations
  ///
  /// Employs debouncing to prevent runaway Firestore reads and duplicate refreshes.
  static Stream<AdminDashboardStats> streamDashboardStats() {
    late StreamController<AdminDashboardStats> controller;
    final List<StreamSubscription> subs = [];
    Timer? debounceTimer;

    void pushLatest() async {
      try {
        final stats = await fetchDashboardStats();
        if (!controller.isClosed) {
          controller.add(stats);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    void schedulePush() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 400), () {
        pushLatest();
      });
    }

    controller = StreamController<AdminDashboardStats>.broadcast(
      onListen: () {
        pushLatest();
        subs.add(
          _firestore
              .collection('users')
              .snapshots()
              .listen((_) => schedulePush()),
        );
        subs.add(
          _firestore
              .collection('donor_profiles')
              .snapshots()
              .listen((_) => schedulePush()),
        );
        subs.add(
          _firestore
              .collection('blood_requests')
              .snapshots()
              .listen((_) => schedulePush()),
        );
        subs.add(
          _firestore
              .collection('donations')
              .snapshots()
              .listen((_) => schedulePush()),
        );
      },
      onCancel: () {
        debounceTimer?.cancel();
        for (final s in subs) {
          s.cancel();
        }
        subs.clear();
      },
    );

    return controller.stream;
  }

  // -------------------------------------------------------------
  // ADMIN-ONLY HIDDEN ITEMS PREFERENCES ('admin_hidden_items')
  // -------------------------------------------------------------

  /// Hides a request or alert for the current administrator.
  /// (Presentation preference only; does not delete or alter underlying records).
  static Future<bool> hideItem({
    required String adminId,
    required String targetType, // 'request' or 'alert'
    required String targetId,
  }) async {
    try {
      final docId = '${adminId}_${targetType}_$targetId';
      await _firestore.collection('admin_hidden_items').doc(docId).set({
        'adminId': adminId,
        'targetType': targetType,
        'targetId': targetId,
        'hiddenAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restores / Unhides a previously hidden request or alert for the administrator.
  static Future<bool> unhideItem({
    required String adminId,
    required String targetType,
    required String targetId,
  }) async {
    try {
      final docId = '${adminId}_${targetType}_$targetId';
      await _firestore.collection('admin_hidden_items').doc(docId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Streams set of hidden target IDs for the current administrator.
  static Stream<Set<String>> streamHiddenItemIds({
    required String adminId,
    required String targetType,
  }) {
    if (adminId.isEmpty) return Stream.value(<String>{});
    return _firestore
        .collection('admin_hidden_items')
        .where('adminId', isEqualTo: adminId)
        .where('targetType', isEqualTo: targetType)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.get('targetId') as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();
        });
  }

  // -------------------------------------------------------------
  // OPERATIONAL AUDIT LOGS ('admin_logs')
  // -------------------------------------------------------------

  /// Streams admin audit logs from 'admin_logs' collection.
  static Stream<List<AdminLogModel>> streamAdminLogs() {
    return _firestore
        .collection('admin_logs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminLogModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Creates an admin log entry with human-readable event description and display names.
  static Future<void> logAction({
    String? actorId,
    required String adminId,
    String? adminName,
    String? actorName,
    String? actorPhotoUrl,
    String? title,
    String? description,
    required String action,
    required String targetCollection,
    required String targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final effectiveActorId = (actorId != null && actorId.isNotEmpty)
          ? actorId
          : adminId;
      final effectiveActorName = actorName ?? adminName ?? 'System Admin';

      await _firestore.collection('admin_logs').add({
        'actorId': effectiveActorId,
        'actorName': effectiveActorName,
        'actorPhotoUrl': actorPhotoUrl,
        'adminId': adminId,
        'adminName': adminName ?? effectiveActorName,
        'title': title,
        'description': description,
        'action': action,
        'targetCollection': targetCollection,
        'targetId': targetId,
        'details': details,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignored
    }
  }

  /// Marks a specific admin log/alert as read without hiding it.
  static Future<bool> markLogAsRead(String logId) async {
    try {
      await _firestore.collection('admin_logs').doc(logId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Marks all current admin logs as read.
  static Future<bool> markAllLogsAsRead() async {
    try {
      final unreadDocs = await _firestore
          .collection('admin_logs')
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // -------------------------------------------------------------
  // USER & CASCADE DATA DELETION
  // -------------------------------------------------------------

  /// Permanently removes a user and cascades deletion through all related
  /// Firestore collections while preserving surviving donors' verified histories:
  /// - `blood_requests` created by user (unverified donations deleted; verified donations anonymized)
  /// - `blood_requests` where user is assigned donor (reopened atomically for community)
  /// - `donations` where user is donor
  /// - `notifications` belonging to user or linked to deleted requests
  /// - `profile_photos/{uid}`
  /// - `donor_profiles/{uid}`
  /// - `users/{uid}` replaced with minimal PII-free deletion tombstone
  /// - immutable audit log in `admin_logs` using non-reversible opaque reference
  ///
  /// Reports exact granular failure stage if any step fails.
  static Future<UserDeletionResult> cascadeDeleteUser(
    String targetUid, {
    required String adminId,
    String? adminName,
  }) async {
    int deletedCount = 0;
    String currentStage = 'initialization';
    String userEmail = '';

    try {
      // 0. Stage: fetch_user_meta
      currentStage = 'fetch_user_meta';
      final userDoc = await _firestore.collection('users').doc(targetUid).get();
      if (userDoc.exists) {
        userEmail = userDoc.get('email') as String? ?? '';
      }

      // 1. Stage: admin_safeguards_check
      currentStage = 'admin_safeguards_check';
      if (targetUid == adminId) {
        return UserDeletionResult(
          success: false,
          failedStage: 'admin_safeguards_check',
          error: 'Administrators cannot delete their own account.',
          totalDeletedDocs: 0,
          targetUid: targetUid,
          targetEmail: userEmail,
        );
      }

      if (userDoc.exists) {
        final role = (userDoc.get('role') as String? ?? '').toLowerCase();
        if (role == 'admin') {
          final allAdmins = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .get();
          if (allAdmins.docs.length <= 1) {
            return UserDeletionResult(
              success: false,
              failedStage: 'admin_safeguards_check',
              error: 'Cannot delete the only remaining administrator account.',
              totalDeletedDocs: 0,
              targetUid: targetUid,
              targetEmail: userEmail,
            );
          }
          return UserDeletionResult(
            success: false,
            failedStage: 'admin_safeguards_check',
            error:
                'Administrators cannot be deleted through ordinary user management actions.',
            totalDeletedDocs: 0,
            targetUid: targetUid,
            targetEmail: userEmail,
          );
        }
      }

      // 2. Stage: blood_requests_created (requests created by this user)
      currentStage = 'blood_requests_created';
      final reqsCreated = await _firestore
          .collection('blood_requests')
          .where('requesterId', isEqualTo: targetUid)
          .get();

      for (final reqDoc in reqsCreated.docs) {
        final reqId = reqDoc.id;

        // Collect all linked donation records (query + deterministic ID)
        final reqDonations = <String, DocumentSnapshot>{};
        final donationsSnap = await _firestore
            .collection('donations')
            .where('bloodRequestId', isEqualTo: reqId)
            .get();
        for (final donDoc in donationsSnap.docs) {
          reqDonations[donDoc.id] = donDoc;
        }

        final detDonRef = _firestore
            .collection('donations')
            .doc('donation_$reqId');
        final detDonDoc = await detDonRef.get();
        if (detDonDoc.exists) {
          reqDonations[detDonDoc.id] = detDonDoc;
        }

        // Handle dependent donations
        for (final donDoc in reqDonations.values) {
          final status = (donDoc.get('status') as String? ?? '').toLowerCase();
          if (status == 'verified') {
            // Documented anonymization: preserve surviving donor's verified contribution & totals
            await donDoc.reference.update({
              'requesterId': 'deleted_account',
              'requesterName': '[Account Deleted]',
              'patientName': '[Redacted for Privacy]',
              'hospitalAddress': '[Redacted]',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            // Unverified or rejected donations are deleted
            await donDoc.reference.delete();
            deletedCount++;
          }
        }

        // Delete notifications linked to this request
        final notifsSnap = await _firestore
            .collection('notifications')
            .where('relatedRequestId', isEqualTo: reqId)
            .get();
        for (final nDoc in notifsSnap.docs) {
          await nDoc.reference.delete();
          deletedCount++;
        }

        // Delete the request itself
        await reqDoc.reference.delete();
        deletedCount++;
      }

      // 3. Stage: blood_requests_as_donor (requests where user was assigned donor)
      currentStage = 'blood_requests_as_donor';
      final reqsAccepted = await _firestore
          .collection('blood_requests')
          .where('donorId', isEqualTo: targetUid)
          .get();

      for (final reqDoc in reqsAccepted.docs) {
        final donationStatus = reqDoc.get('donationStatus') as String? ?? '';
        if (donationStatus != 'verified') {
          // Reopen request to eligible community donors
          await reqDoc.reference.update({
            'donorId': FieldValue.delete(),
            'donorName': FieldValue.delete(),
            'donorPhotoUrl': FieldValue.delete(),
            'donorPhone': FieldValue.delete(),
            'donorBloodGroup': FieldValue.delete(),
            'donorCity': FieldValue.delete(),
            'donationStatus': 'waiting_donor',
            'acceptedAt': FieldValue.delete(),
            'status': 'approved',
            'visibility': 'published',
            'lastReleasedReason':
                'Assigned donor account was deleted by administrator.',
            'lastReleasedAt': FieldValue.serverTimestamp(),
            'reopenedAt': FieldValue.serverTimestamp(),
            'feedUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Notify requester
          final requesterId = reqDoc.get('requesterId') as String? ?? '';
          if (requesterId.isNotEmpty) {
            await _firestore.collection('notifications').add({
              'userId': requesterId,
              'title': 'Request Reopened',
              'message':
                  'The donor previously assigned to your request was removed. Your request has been reopened for community donors.',
              'type': 'donor_released',
              'relatedRequestId': reqDoc.id,
              'actorName': adminName ?? 'System Administrator',
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // Completed verified request: anonymize deleted donor reference
          await reqDoc.reference.update({
            'donorName': '[Account Deleted]',
            'donorPhone': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 4. Stage: donations_as_donor (donations where this user was donor)
      currentStage = 'donations_as_donor';
      final donationsAsDonor = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: targetUid)
          .get();
      for (final donDoc in donationsAsDonor.docs) {
        await donDoc.reference.delete();
        deletedCount++;
      }

      // 5. Stage: notifications_query & notifications_delete
      currentStage = 'notifications_query';
      final userNotifs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: targetUid)
          .get();

      currentStage = 'notifications_delete';
      for (final nDoc in userNotifs.docs) {
        await nDoc.reference.delete();
        deletedCount++;
      }

      // 5b. Stage: device_tokens_delete (safe purge if device token records exist)
      currentStage = 'device_tokens_delete';
      try {
        final deviceTokens = await _firestore
            .collection('device_tokens')
            .where('userId', isEqualTo: targetUid)
            .get();
        for (final tokenDoc in deviceTokens.docs) {
          await tokenDoc.reference.delete();
          deletedCount++;
        }
      } catch (_) {}

      // 6. Stage: hidden_preferences (owner-scoped admin preferences only)
      currentStage = 'hidden_preferences';
      final adminHiddenSnap = await _firestore
          .collection('admin_hidden_items')
          .where('adminId', isEqualTo: targetUid)
          .get();
      for (final hDoc in adminHiddenSnap.docs) {
        await hDoc.reference.delete();
        deletedCount++;
      }

      // 7. Stage: profile_documents
      currentStage = 'profile_documents';
      final photoRef = _firestore.collection('profile_photos').doc(targetUid);
      final photoDoc = await photoRef.get();
      if (photoDoc.exists) {
        await photoRef.delete();
        deletedCount++;
      }

      final donorRef = _firestore.collection('donor_profiles').doc(targetUid);
      final donorDoc = await donorRef.get();
      if (donorDoc.exists) {
        await donorRef.delete();
        deletedCount++;
      }

      // 8. Stage: tombstone_creation (zero PII; prevents silent recreation in Firestore)
      currentStage = 'tombstone_creation';
      await _firestore.collection('users').doc(targetUid).set({
        'accountStatus': 'deleted',
        'role': 'disabled',
        'deletedAt': FieldValue.serverTimestamp(),
      });
      deletedCount++;

      // 9. Stage: audit_log (privacy-preserving opaque reference with NO PII)
      currentStage = 'audit_log';
      final opaqueRef =
          'user_${sha256.convert(utf8.encode(targetUid)).toString().substring(0, 16)}';
      await logAction(
        actorId: adminId,
        adminId: adminId,
        adminName: adminName,
        action: 'user_deleted',
        targetCollection: 'users',
        targetId: opaqueRef,
        title: 'User Application Data Deleted',
        description:
            'Permanently deleted user application records ($deletedCount documents purged). Firebase Authentication identity pending manual console cleanup.',
        details: {
          'opaqueUserRef': opaqueRef,
          'totalDeletedDocs': deletedCount,
          'authAccountPendingManualDeletion': true,
        },
      );

      return UserDeletionResult(
        success: true,
        totalDeletedDocs: deletedCount,
        targetUid: targetUid,
        targetEmail: userEmail,
        authAccountPendingManualDeletion: true,
      );
    } catch (e) {
      return UserDeletionResult(
        success: false,
        failedStage: currentStage,
        error: e.toString(),
        totalDeletedDocs: deletedCount,
        targetUid: targetUid,
        targetEmail: userEmail,
      );
    }
  }
}
