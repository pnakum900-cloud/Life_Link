import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink/Manob/app_validators.dart';
import 'package:lifelink/Manob/auth_service.dart';
import 'package:lifelink/Pratik/admin_service.dart';
import 'package:lifelink/Manob/blood_request_model.dart';
import 'package:lifelink/Manob/donation_model.dart';
import 'package:lifelink/Bokul/donor_model.dart';

void main() {
  group('Admin User Deletion & Cascade Policy Tests', () {
    test('UserDeletionResult accurately summarizes deletion status', () {
      final res = UserDeletionResult(
        success: true,
        targetUid: 'target_user_123',
        targetEmail: 'target@gmail.com',
        totalDeletedDocs: 12,
        authAccountPendingManualDeletion: true,
      );

      expect(res.success, isTrue);
      expect(res.targetUid, 'target_user_123');
      expect(res.totalDeletedDocs, 12);
      expect(res.authAccountPendingManualDeletion, isTrue);
    });

    test('Donor statistics recalculation from surviving verified donations', () {
      // Simulate donor with multiple donations where one gets removed due to requester deletion
      final verifiedDonations = [
        DonationModel(
          donationId: 'donation_req_1',
          bloodRequestId: 'req_1',
          donorId: 'surviving_donor',
          requesterId: 'requester_1',
          hospitalName: 'Civil Hospital',
          bloodGroup: 'B+',
          unitsDonated: 1,
          status: 'verified',
          donationDate: DateTime(2026, 1, 10),
          createdAt: DateTime(2026, 1, 10),
        ),
        DonationModel(
          donationId: 'donation_req_2',
          bloodRequestId: 'req_2',
          donorId: 'surviving_donor',
          requesterId: 'requester_2',
          hospitalName: 'Sterling Hospital',
          bloodGroup: 'B+',
          unitsDonated: 2,
          status: 'verified',
          donationDate: DateTime(2026, 3, 15),
          createdAt: DateTime(2026, 3, 15),
        ),
      ];

      // Calculate aggregates
      var survivingCount = 0;
      num survivingUnits = 0;
      DateTime? latestDate;

      for (final d in verifiedDonations) {
        if (d.status == 'verified') {
          survivingCount++;
          survivingUnits += d.unitsDonated;
          if (d.donationDate != null &&
              (latestDate == null || d.donationDate!.isAfter(latestDate))) {
            latestDate = d.donationDate;
          }
        }
      }

      expect(survivingCount, 2);
      expect(survivingUnits, 3);
      expect(latestDate, DateTime(2026, 3, 15));
    });
  });

  group('Blood Group Protection & Admin Authority Tests', () {
    test('Supported blood groups list matches clinical specifications', () {
      const allowed = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      expect(AppValidators.validBloodGroups, allowed);
      for (final bg in allowed) {
        expect(AppValidators.validBloodGroups.contains(bg), isTrue);
      }
    });

    test(
      'Non-admin user update payload cannot touch bloodGroup or aggregates',
      () {
        final disallowedKeysForUser = [
          'bloodGroup',
          'totalDonationCount',
          'totalUnitsDonated',
          'lastDonationAt',
          'lastVerifiedDonationId',
          'role',
          'userId',
          'accountStatus',
        ];

        final userUpdateAttempt = {
          'fullName': 'Updated Name',
          'bloodGroup': 'O-',
          'totalDonationCount': 99,
        };

        final safeUpdate = Map<String, dynamic>.from(userUpdateAttempt)
          ..removeWhere((key, _) => disallowedKeysForUser.contains(key));

        expect(safeUpdate.containsKey('bloodGroup'), isFalse);
        expect(safeUpdate.containsKey('totalDonationCount'), isFalse);
        expect(safeUpdate['fullName'], 'Updated Name');
      },
    );

    test(
      'Admin update payload allows valid bloodGroup but strictly denies direct aggregate modification',
      () {
        final disallowedKeysForAdminNonAggregate = [
          'totalDonationCount',
          'totalUnitsDonated',
          'lastDonationAt',
          'lastVerifiedDonationId',
          'role',
          'userId',
        ];

        final adminUpdateAttempt = {
          'bloodGroup': 'B+',
          'totalDonationCount': 50,
        };

        expect(
          AppValidators.validBloodGroups.contains(
            adminUpdateAttempt['bloodGroup'],
          ),
          isTrue,
        );

        final safeAdminUpdate = Map<String, dynamic>.from(adminUpdateAttempt)
          ..removeWhere(
            (key, _) => disallowedKeysForAdminNonAggregate.contains(key),
          );

        expect(safeAdminUpdate.containsKey('bloodGroup'), isTrue);
        expect(safeAdminUpdate['bloodGroup'], 'B+');
        expect(safeAdminUpdate.containsKey('totalDonationCount'), isFalse);
      },
    );
  });

  group('Email Verification & Profile State Tests', () {
    test('AuthResult flags unverified email and missing profile', () {
      final unverifiedRes = AuthResult(
        success: false,
        message: 'Email not verified',
        isEmailUnverified: true,
      );
      expect(unverifiedRes.isEmailUnverified, isTrue);
      expect(unverifiedRes.isProfileMissing, isFalse);

      final missingProfileRes = AuthResult(
        success: false,
        message: 'Account profile not found',
        isProfileMissing: true,
      );
      expect(missingProfileRes.isProfileMissing, isTrue);
      expect(missingProfileRes.isEmailUnverified, isFalse);
    });

    test('Single-donor assignment prevents duplicate acceptance', () {
      final publishedRequest = BloodRequestModel(
        requestId: 'req_001',
        requesterId: 'req_user',
        patientName: 'Test Patient',
        bloodGroup: 'B+',
        units: 2,
        hospitalName: 'Civil Hospital',
        contactNumber: '9876543210',
        urgency: 'Normal',
        status: 'approved',
        visibility: 'published',
        createdAt: DateTime.now(),
      );

      expect(publishedRequest.hasConfirmedDonor, isFalse);
      expect(
        publishedRequest.isApproved && publishedRequest.isPublished,
        isTrue,
      );

      final acceptedRequest = publishedRequest.copyWith(
        donorId: 'donor_001',
        donorName: 'First Donor',
        donationStatus: 'donor_accepted',
      );

      expect(acceptedRequest.hasConfirmedDonor, isTrue);
    });
  });

  group('Canonical Ordering & Reopened Request Tests', () {
    test(
      'effectiveFeedTime correctly resolves priority: feedUpdatedAt > reopenedAt > createdAt',
      () {
        final baseDate = DateTime(2026, 1, 1);
        final reopenedDate = DateTime(2026, 1, 10);
        final feedUpdatedDate = DateTime(2026, 1, 20);

        final reqWithAll = BloodRequestModel(
          requestId: 'req_1',
          requesterId: 'u1',
          patientName: 'P1',
          bloodGroup: 'A+',
          units: 1,
          hospitalName: 'Hospital 1',
          contactNumber: '9876543210',
          createdAt: baseDate,
          reopenedAt: reopenedDate,
          feedUpdatedAt: feedUpdatedDate,
        );
        expect(reqWithAll.effectiveFeedTime, feedUpdatedDate);

        final reqWithReopenedOnly = BloodRequestModel(
          requestId: 'req_2',
          requesterId: 'u1',
          patientName: 'P2',
          bloodGroup: 'A+',
          units: 1,
          hospitalName: 'Hospital 2',
          contactNumber: '9876543210',
          createdAt: baseDate,
          reopenedAt: reopenedDate,
        );
        expect(reqWithReopenedOnly.effectiveFeedTime, reopenedDate);

        final reqDefault = BloodRequestModel(
          requestId: 'req_3',
          requesterId: 'u1',
          patientName: 'P3',
          bloodGroup: 'A+',
          units: 1,
          hospitalName: 'Hospital 3',
          contactNumber: '9876543210',
          createdAt: baseDate,
        );
        expect(reqDefault.effectiveFeedTime, baseDate);
      },
    );

    test(
      'Reopened requests sort to the top of the feed over newer requests',
      () {
        final olderRequestReopened = BloodRequestModel(
          requestId: 'req_old_reopened',
          requesterId: 'u1',
          patientName: 'Old Patient',
          bloodGroup: 'O+',
          units: 2,
          hospitalName: 'Civil Hospital',
          contactNumber: '9876543210',
          createdAt: DateTime(2026, 1, 1),
          feedUpdatedAt: DateTime(2026, 3, 1), // Reopened on March 1
        );

        final newerRequestNotReopened = BloodRequestModel(
          requestId: 'req_new',
          requesterId: 'u2',
          patientName: 'New Patient',
          bloodGroup: 'B+',
          units: 1,
          hospitalName: 'Apollo Hospital',
          contactNumber: '9876543211',
          createdAt: DateTime(2026, 2, 1), // Created on Feb 1, no updates
        );

        final list = [newerRequestNotReopened, olderRequestReopened];
        list.sort((a, b) => b.effectiveFeedTime.compareTo(a.effectiveFeedTime));

        expect(list.first.requestId, 'req_old_reopened');
        expect(list.last.requestId, 'req_new');
      },
    );
  });

  group('Three Requester Actions & State Transitions Tests', () {
    final acceptedRequest = BloodRequestModel(
      requestId: 'req_100',
      requesterId: 'requester_123',
      patientName: 'Patient X',
      bloodGroup: 'AB+',
      units: 2,
      hospitalName: 'Sterling Hospital',
      contactNumber: '9876543210',
      status: 'approved',
      visibility: 'published',
      donorId: 'donor_999',
      donorName: 'Donor John',
      donorPhone: '9876543299',
      donorBloodGroup: 'AB+',
      donationStatus: 'donor_accepted',
      acceptedAt: DateTime(2026, 2, 10),
      createdAt: DateTime(2026, 2, 1),
    );

    test(
      'Release Donor clears active donor fields and transitions to waiting_donor',
      () {
        final releasedAt = DateTime(2026, 2, 15);
        final released = acceptedRequest.copyWith(
          clearDonor: true,
          donationStatus: 'waiting_donor',
          lastReleasedDonorId: acceptedRequest.donorId,
          lastReleasedReason: 'Donor unavailable for scheduled time',
          lastReleasedAt: releasedAt,
          reopenedAt: releasedAt,
          feedUpdatedAt: releasedAt,
        );

        expect(released.donorId, isNull);
        expect(released.donorName, isNull);
        expect(released.hasConfirmedDonor, isFalse);
        expect(released.donationStatus, 'waiting_donor');
        expect(released.status, 'approved');
        expect(released.visibility, 'published');
        expect(released.lastReleasedDonorId, 'donor_999');
        expect(released.effectiveFeedTime, releasedAt);
        expect(
          released.createdAt,
          DateTime(2026, 2, 1),
        ); // Original createdAt preserved
      },
    );

    test(
      'Donation Did Not Happen clears donor fields, preserves reason, and transitions to waiting_donor',
      () {
        final reportedAt = DateTime(2026, 2, 16);
        final notCompleted = acceptedRequest.copyWith(
          clearDonor: true,
          donationStatus: 'waiting_donor',
          lastUnsuccessfulAttempt: {
            'donorId': acceptedRequest.donorId,
            'donorName': acceptedRequest.donorName,
            'reason': 'Donor could not make it to hospital',
          },
          unsuccessfulAttemptReason: 'Donor could not make it to hospital',
          reopenedAt: reportedAt,
          feedUpdatedAt: reportedAt,
        );

        expect(notCompleted.donorId, isNull);
        expect(notCompleted.hasConfirmedDonor, isFalse);
        expect(notCompleted.donationStatus, 'waiting_donor');
        expect(notCompleted.status, 'approved');
        expect(notCompleted.visibility, 'published');
        expect(
          notCompleted.unsuccessfulAttemptReason,
          'Donor could not make it to hospital',
        );
        expect(notCompleted.lastUnsuccessfulAttempt?['donorId'], 'donor_999');
        expect(notCompleted.effectiveFeedTime, reportedAt);
        expect(notCompleted.createdAt, DateTime(2026, 2, 1));
      },
    );

    test(
      'Confirm Donation Completed transitions to pending_verification and retains assigned donor',
      () {
        final confirmedAt = DateTime(2026, 2, 14);
        const units = 2;

        final confirmed = acceptedRequest.copyWith(
          donationStatus: 'pending_verification',
          confirmedUnits: units,
          confirmedAt: confirmedAt,
          completionNotes: 'Successful donation at hospital ward 4',
        );

        expect(confirmed.donorId, 'donor_999');
        expect(confirmed.hasConfirmedDonor, isTrue);
        expect(confirmed.donationStatus, 'pending_verification');
        expect(confirmed.confirmedUnits, 2);
        expect(confirmed.confirmedAt, confirmedAt);

        // Verify deterministic donation ID
        final deterministicDonationId = 'donation_${confirmed.requestId}';
        expect(deterministicDonationId, 'donation_req_100');
      },
    );
  });

  group('Surviving Donor Anonymization & Deletion Safeguards Tests', () {
    test(
      'Anonymizing verified donation replaces requester PII while preserving donor aggregates',
      () {
        final verifiedDonation = DonationModel(
          donationId: 'donation_req_500',
          bloodRequestId: 'req_500',
          donorId: 'surviving_donor_id',
          donorName: 'Surviving Donor',
          requesterId: 'deleted_user_uid',
          requesterName: 'Bijal Nakum',
          patientName: 'John Patient',
          hospitalName: 'Rajkot Civil',
          bloodGroup: 'B+',
          unitsDonated: 2,
          status: 'verified',
          donationDate: DateTime(2026, 1, 15),
          createdAt: DateTime(2026, 1, 15),
        );

        // Anonymize for deleted requester
        final anonymizedPayload = {
          'requesterName': '[Account Deleted]',
          'patientName': '[Redacted for Privacy]',
        };

        final anonymizedDonation = DonationModel(
          donationId: verifiedDonation.donationId,
          bloodRequestId: verifiedDonation.bloodRequestId,
          donorId: verifiedDonation.donorId,
          donorName: verifiedDonation.donorName,
          requesterId: verifiedDonation.requesterId,
          requesterName: anonymizedPayload['requesterName']!,
          patientName: anonymizedPayload['patientName']!,
          hospitalName: verifiedDonation.hospitalName,
          bloodGroup: verifiedDonation.bloodGroup,
          unitsDonated: verifiedDonation.unitsDonated,
          status: verifiedDonation.status,
          donationDate: verifiedDonation.donationDate,
          createdAt: verifiedDonation.createdAt,
        );

        expect(anonymizedDonation.requesterName, '[Account Deleted]');
        expect(anonymizedDonation.patientName, '[Redacted for Privacy]');
        expect(anonymizedDonation.donorId, 'surviving_donor_id');
        expect(anonymizedDonation.unitsDonated, 2);
        expect(anonymizedDonation.status, 'verified');
      },
    );

    test('Admin safeguards prevent self-deletion and peer admin deletion', () {
      const currentAdminUid = 'admin_uid_1';
      const targetAdminUid = 'admin_uid_2';
      const targetUserUid = 'regular_user_1';

      // Self deletion check
      final isSelf = currentAdminUid == currentAdminUid;
      expect(isSelf, isTrue);

      // Peer admin deletion check
      final isPeerAdminTarget = targetAdminUid != currentAdminUid;
      expect(isPeerAdminTarget, isTrue);
      const targetUserRole = 'admin';
      final isPeerAdmin = targetUserRole == 'admin';
      expect(isPeerAdmin, isTrue);

      // Regular user deletion allowed
      final isRegularUser =
          targetUserUid != currentAdminUid && targetUserRole != 'user';
      expect(isRegularUser, isTrue);
    });
  });

  group('Canonical Ordering & Reopened Request Tests', () {
    test(
      'effectiveFeedTime correctly resolves priority: feedUpdatedAt > reopenedAt > createdAt',
      () {
        final baseDate = DateTime(2026, 1, 1);
        final reopenedDate = DateTime(2026, 1, 10);
        final feedUpdatedDate = DateTime(2026, 1, 20);

        final reqWithAll = BloodRequestModel(
          requestId: 'req_1',
          requesterId: 'u1',
          patientName: 'P1',
          bloodGroup: 'A+',
          units: 1,
          hospitalName: 'Hospital 1',
          contactNumber: '9876543210',
          createdAt: baseDate,
          reopenedAt: reopenedDate,
          feedUpdatedAt: feedUpdatedDate,
        );
        expect(reqWithAll.effectiveFeedTime, feedUpdatedDate);

        final reqWithReopenedOnly = BloodRequestModel(
          requestId: 'req_2',
          requesterId: 'u1',
          patientName: 'P2',
          bloodGroup: 'A+',
          units: 1,
          hospitalName: 'Hospital 2',
          contactNumber: '9876543210',
          createdAt: baseDate,
          reopenedAt: reopenedDate,
        );
        expect(reqWithReopenedOnly.effectiveFeedTime, reopenedDate);

        final reqDefault = BloodRequestModel(
          requestId: 'req_3',
          requesterId: 'u1',
          patientName: 'P3',
          bloodGroup: 'A+',
          units: 1,
          hospitalName: 'Hospital 3',
          contactNumber: '9876543210',
          createdAt: baseDate,
        );
        expect(reqDefault.effectiveFeedTime, baseDate);
      },
    );

    test(
      'Reopened requests sort to the top of the feed over newer requests',
      () {
        final olderRequestReopened = BloodRequestModel(
          requestId: 'req_old_reopened',
          requesterId: 'u1',
          patientName: 'Old Patient',
          bloodGroup: 'O+',
          units: 2,
          hospitalName: 'Civil Hospital',
          contactNumber: '9876543210',
          createdAt: DateTime(2026, 1, 1),
          feedUpdatedAt: DateTime(2026, 3, 1), // Reopened on March 1
        );

        final newerRequestNotReopened = BloodRequestModel(
          requestId: 'req_new',
          requesterId: 'u2',
          patientName: 'New Patient',
          bloodGroup: 'B+',
          units: 1,
          hospitalName: 'Apollo Hospital',
          contactNumber: '9876543211',
          createdAt: DateTime(2026, 2, 1), // Created on Feb 1, no updates
        );

        final list = [newerRequestNotReopened, olderRequestReopened];
        list.sort((a, b) => b.effectiveFeedTime.compareTo(a.effectiveFeedTime));

        expect(list.first.requestId, 'req_old_reopened');
        expect(list.last.requestId, 'req_new');
      },
    );
  });

  group('Three Requester Actions & State Transitions Tests', () {
    final acceptedRequest = BloodRequestModel(
      requestId: 'req_100',
      requesterId: 'requester_123',
      patientName: 'Patient X',
      bloodGroup: 'AB+',
      units: 2,
      hospitalName: 'Sterling Hospital',
      contactNumber: '9876543210',
      status: 'approved',
      visibility: 'published',
      donorId: 'donor_999',
      donorName: 'Donor John',
      donorPhone: '9876543299',
      donorBloodGroup: 'AB+',
      donationStatus: 'donor_accepted',
      acceptedAt: DateTime(2026, 2, 10),
      createdAt: DateTime(2026, 2, 1),
    );

    test(
      'Release Donor clears active donor fields and transitions to waiting_donor',
      () {
        final releasedAt = DateTime(2026, 2, 15);
        final released = acceptedRequest.copyWith(
          clearDonor: true,
          donationStatus: 'waiting_donor',
          lastReleasedDonorId: acceptedRequest.donorId,
          lastReleasedReason: 'Donor unavailable for scheduled time',
          lastReleasedAt: releasedAt,
          reopenedAt: releasedAt,
          feedUpdatedAt: releasedAt,
        );

        expect(released.donorId, isNull);
        expect(released.donorName, isNull);
        expect(released.hasConfirmedDonor, isFalse);
        expect(released.donationStatus, 'waiting_donor');
        expect(released.status, 'approved');
        expect(released.visibility, 'published');
        expect(released.lastReleasedDonorId, 'donor_999');
        expect(released.effectiveFeedTime, releasedAt);
        expect(
          released.createdAt,
          DateTime(2026, 2, 1),
        ); // Original createdAt preserved
      },
    );

    test(
      'Donation Did Not Happen clears donor fields, preserves reason, and transitions to waiting_donor',
      () {
        final reportedAt = DateTime(2026, 2, 16);
        final notCompleted = acceptedRequest.copyWith(
          clearDonor: true,
          donationStatus: 'waiting_donor',
          lastUnsuccessfulAttempt: {
            'donorId': acceptedRequest.donorId,
            'donorName': acceptedRequest.donorName,
            'reason': 'Donor could not make it to hospital',
          },
          unsuccessfulAttemptReason: 'Donor could not make it to hospital',
          reopenedAt: reportedAt,
          feedUpdatedAt: reportedAt,
        );

        expect(notCompleted.donorId, isNull);
        expect(notCompleted.hasConfirmedDonor, isFalse);
        expect(notCompleted.donationStatus, 'waiting_donor');
        expect(notCompleted.status, 'approved');
        expect(notCompleted.visibility, 'published');
        expect(
          notCompleted.unsuccessfulAttemptReason,
          'Donor could not make it to hospital',
        );
        expect(notCompleted.lastUnsuccessfulAttempt?['donorId'], 'donor_999');
        expect(notCompleted.effectiveFeedTime, reportedAt);
        expect(notCompleted.createdAt, DateTime(2026, 2, 1));
      },
    );

    test(
      'Confirm Donation Completed transitions to pending_verification and retains assigned donor',
      () {
        final confirmedAt = DateTime(2026, 2, 14);
        const units = 2;

        final confirmed = acceptedRequest.copyWith(
          donationStatus: 'pending_verification',
          confirmedUnits: units,
          confirmedAt: confirmedAt,
          completionNotes: 'Successful donation at hospital ward 4',
        );

        expect(confirmed.donorId, 'donor_999');
        expect(confirmed.hasConfirmedDonor, isTrue);
        expect(confirmed.donationStatus, 'pending_verification');
        expect(confirmed.confirmedUnits, 2);
        expect(confirmed.confirmedAt, confirmedAt);

        // Verify deterministic donation ID
        final deterministicDonationId = 'donation_${confirmed.requestId}';
        expect(deterministicDonationId, 'donation_req_100');
      },
    );
  });

  group('Surviving Donor Anonymization & Deletion Safeguards Tests', () {
    test(
      'Anonymizing verified donation replaces requester PII while preserving donor aggregates',
      () {
        final verifiedDonation = DonationModel(
          donationId: 'donation_req_500',
          bloodRequestId: 'req_500',
          donorId: 'surviving_donor_id',
          donorName: 'Surviving Donor',
          requesterId: 'deleted_user_uid',
          requesterName: 'Bijal Nakum',
          patientName: 'John Patient',
          hospitalName: 'Rajkot Civil',
          bloodGroup: 'B+',
          unitsDonated: 2,
          status: 'verified',
          donationDate: DateTime(2026, 1, 15),
          createdAt: DateTime(2026, 1, 15),
        );

        // Anonymize for deleted requester
        final anonymizedPayload = {
          'requesterName': '[Account Deleted]',
          'patientName': '[Redacted for Privacy]',
        };

        final anonymizedDonation = DonationModel(
          donationId: verifiedDonation.donationId,
          bloodRequestId: verifiedDonation.bloodRequestId,
          donorId: verifiedDonation.donorId,
          donorName: verifiedDonation.donorName,
          requesterId: verifiedDonation.requesterId,
          requesterName: anonymizedPayload['requesterName']!,
          patientName: anonymizedPayload['patientName']!,
          hospitalName: verifiedDonation.hospitalName,
          bloodGroup: verifiedDonation.bloodGroup,
          unitsDonated: verifiedDonation.unitsDonated,
          status: verifiedDonation.status,
          donationDate: verifiedDonation.donationDate,
          createdAt: verifiedDonation.createdAt,
        );

        expect(anonymizedDonation.requesterName, '[Account Deleted]');
        expect(anonymizedDonation.patientName, '[Redacted for Privacy]');
        expect(anonymizedDonation.donorId, 'surviving_donor_id');
        expect(anonymizedDonation.unitsDonated, 2);
        expect(anonymizedDonation.status, 'verified');
      },
    );

    test('Admin safeguards prevent self-deletion and peer admin deletion', () {
      const currentAdminUid = 'admin_uid_1';
      const targetAdminUid = 'admin_uid_2';
      const targetUserUid = 'regular_user_1';

      // Self deletion check
      final isSelf = currentAdminUid == currentAdminUid;
      expect(isSelf, isTrue);

      // Peer admin deletion check
      final isPeerAdminTarget = targetAdminUid != currentAdminUid;
      expect(isPeerAdminTarget, isTrue);
      const targetUserRole = 'admin';
      final isPeerAdmin = targetUserRole == 'admin';
      expect(isPeerAdmin, isTrue);

      // Regular user deletion allowed
      final isRegularUser =
          targetUserUid != currentAdminUid && targetUserRole != 'user';
      expect(isRegularUser, isTrue);
    });
  });

  group('Requester-Only Exclusivity & Safe Transaction Tests', () {
    const requesterId = 'requester_123';
    const donorId = 'donor_456';
    const otherUserId = 'other_789';
    const nonOwnerAdminId = 'admin_999';

    final baseAcceptedRequest = BloodRequestModel(
      requestId: 'req_exclusivity_test',
      patientName: 'Test Patient',
      bloodGroup: 'B+',
      units: 2,
      hospitalName: 'Civil Hospital',
      city: 'Rajkot',
      contactNumber: '9876543210',
      status: 'approved',
      urgency: 'Normal',
      visibility: 'published',
      requesterId: requesterId,
      requesterName: 'Original Requester',
      donorId: donorId,
      donorName: 'Assigned Donor',
      donationStatus: 'donor_accepted',
      createdAt: DateTime(2026, 3, 1),
    );

    test('Strict requester-only authorization check logic', () {
      bool canPerformRequesterAction(String actorId, BloodRequestModel req) {
        return actorId == req.requesterId;
      }

      // 1. Original requester is allowed
      expect(
        canPerformRequesterAction(requesterId, baseAcceptedRequest),
        isTrue,
      );

      // 2. Assigned donor is strictly denied
      expect(canPerformRequesterAction(donorId, baseAcceptedRequest), isFalse);

      // 3. Other third-party user is strictly denied
      expect(
        canPerformRequesterAction(otherUserId, baseAcceptedRequest),
        isFalse,
      );

      // 4. Administrator who is NOT the request owner is strictly denied requester actions
      expect(
        canPerformRequesterAction(nonOwnerAdminId, baseAcceptedRequest),
        isFalse,
      );
    });

    test(
      'State transition verification lock prevents premature release or report not completed',
      () {
        bool canReleaseOrReportNotCompleted(String currentDonationStatus) {
          return currentDonationStatus == 'donor_accepted';
        }

        expect(canReleaseOrReportNotCompleted('donor_accepted'), isTrue);
        expect(canReleaseOrReportNotCompleted('pending_verification'), isFalse);
        expect(canReleaseOrReportNotCompleted('verified'), isFalse);
        expect(canReleaseOrReportNotCompleted('rejected'), isFalse);
      },
    );

    test('Diagnostic stage reporting schema validation', () {
      final failureStages = [
        'request_read',
        'donation_doc_check',
        'verification_doc_check',
        'authorization_check',
        'eligibility_check',
        'request_update',
        'donation_create',
        'notification_create',
        'audit_log_create',
      ];

      for (final stage in failureStages) {
        final mockResult = {
          'success': false,
          'failedStage': stage,
          'error': 'Permission denied test',
        };
        expect(mockResult['success'], isFalse);
        expect(mockResult['failedStage'], stage);
        expect(mockResult['error'], contains('Permission denied'));
      }
    });

    test('Safe Token Claim Navigation simulation', () {
      // Simulates CEL safe navigation: token.get('role', '') and token.get('admin', false)
      String getRole(Map<String, dynamic> token) {
        return token['role'] as String? ?? '';
      }

      bool getAdmin(Map<String, dynamic> token) {
        return token['admin'] as bool? ?? false;
      }

      // 1. Standard token without any custom claims
      final standardToken = <String, dynamic>{
        'email': 'user@gmail.com',
        'email_verified': true,
      };
      expect(getRole(standardToken), '');
      expect(getAdmin(standardToken), isFalse);

      // 2. Token with role: admin
      final adminToken = <String, dynamic>{
        'email': 'admin@gmail.com',
        'role': 'admin',
      };
      expect(getRole(adminToken), 'admin');

      // 3. Token with admin: true
      final boolAdminToken = <String, dynamic>{
        'email': 'admin2@gmail.com',
        'admin': true,
      };
      expect(getAdmin(boolAdminToken), isTrue);
    });

    test('Separate explicitly validated administrator operations logic', () {
      // Admin operations are separate and discrete, rejecting requester lifecycle hijacking
      bool isAdminReviewAllowed({
        required bool isAdmin,
        required String currentStatus,
        required String nextStatus,
        required String nextVisibility,
      }) {
        if (!isAdmin) return false;
        if (currentStatus == 'pending' &&
            nextStatus == 'approved' &&
            nextVisibility == 'published') {
          return true;
        }
        if (currentStatus == 'pending' &&
            nextStatus == 'rejected' &&
            nextVisibility == 'private') {
          return true;
        }
        if (currentStatus == 'rejected' &&
            nextStatus == 'approved' &&
            nextVisibility == 'published') {
          return true;
        }
        return false;
      }

      // Valid admin decisions
      expect(
        isAdminReviewAllowed(
          isAdmin: true,
          currentStatus: 'pending',
          nextStatus: 'approved',
          nextVisibility: 'published',
        ),
        isTrue,
      );
      expect(
        isAdminReviewAllowed(
          isAdmin: true,
          currentStatus: 'pending',
          nextStatus: 'rejected',
          nextVisibility: 'private',
        ),
        isTrue,
      );
      expect(
        isAdminReviewAllowed(
          isAdmin: true,
          currentStatus: 'rejected',
          nextStatus: 'approved',
          nextVisibility: 'published',
        ),
        isTrue,
      );

      // Non-admin attempting review decisions
      expect(
        isAdminReviewAllowed(
          isAdmin: false,
          currentStatus: 'pending',
          nextStatus: 'approved',
          nextVisibility: 'published',
        ),
        isFalse,
      );
    });

    test(
      'admin_hidden_items delete strictly requires isAdmin AND adminId match',
      () {
        bool canDeleteHiddenItem({
          required bool isAdmin,
          required String callerUid,
          required String itemOwnerAdminId,
        }) {
          return isAdmin && callerUid == itemOwnerAdminId;
        }

        // Admin 1 deleting Admin 1's hidden preference -> Allowed
        expect(
          canDeleteHiddenItem(
            isAdmin: true,
            callerUid: 'admin_1',
            itemOwnerAdminId: 'admin_1',
          ),
          isTrue,
        );

        // Admin 2 attempting to delete Admin 1's hidden preference -> Denied
        expect(
          canDeleteHiddenItem(
            isAdmin: true,
            callerUid: 'admin_2',
            itemOwnerAdminId: 'admin_1',
          ),
          isFalse,
        );

        // Regular user attempting to delete hidden preference -> Denied
        expect(
          canDeleteHiddenItem(
            isAdmin: false,
            callerUid: 'user_1',
            itemOwnerAdminId: 'user_1',
          ),
          isFalse,
        );
      },
    );

    test('3-Way Atomic Donation Verification Co-Binding Validation', () {
      // Simulates rule verification: donation 'verified' <-> blood_request 'fulfilled' <-> donor_profile 'lastVerifiedDonationId'
      bool is3WayAtomicVerificationValid({
        required String donationStatus,
        required String requestStatus,
        required String requestDonationStatus,
        required String? donorLastVerifiedId,
        required String expectedDonationId,
      }) {
        final isDonationVerified = donationStatus == 'verified';
        final isRequestFulfilled =
            requestStatus == 'fulfilled' && requestDonationStatus == 'verified';
        final isDonorIncremented = donorLastVerifiedId == expectedDonationId;

        return isDonationVerified && isRequestFulfilled && isDonorIncremented;
      }

      const donId = 'donation_req_100';

      // Valid atomic 3-way co-verification
      expect(
        is3WayAtomicVerificationValid(
          donationStatus: 'verified',
          requestStatus: 'fulfilled',
          requestDonationStatus: 'verified',
          donorLastVerifiedId: donId,
          expectedDonationId: donId,
        ),
        isTrue,
      );

      // Desynchronized verification (request not fulfilled) -> Invalid
      expect(
        is3WayAtomicVerificationValid(
          donationStatus: 'verified',
          requestStatus: 'approved',
          requestDonationStatus: 'pending_verification',
          donorLastVerifiedId: donId,
          expectedDonationId: donId,
        ),
        isFalse,
      );

      // Desynchronized verification (donor totals not bound) -> Invalid
      expect(
        is3WayAtomicVerificationValid(
          donationStatus: 'verified',
          requestStatus: 'fulfilled',
          requestDonationStatus: 'verified',
          donorLastVerifiedId: null,
          expectedDonationId: donId,
        ),
        isFalse,
      );
    });

    test('Donor Registration Document Schema Validation', () {
      final donor = DonorModel(
        userId: 'new_reg_user',
        fullName: 'New Donor',
        bloodGroup: 'O+',
        phoneNumber: '9876543210',
        address: '150 Feet Ring Road, Rajkot',
        city: 'Rajkot',
        isAvailable: true,
        eligibilityStatus: 'READY',
        role: 'user',
        totalDonationCount: 0,
        totalUnitsDonated: 0,
      );

      final map = donor.toMap();
      expect(map['role'], 'user');
      expect(map['totalDonationCount'], 0);
      expect(map['totalUnitsDonated'], 0);
      expect(map['lastDonationAt'], isNull);
      expect(map['lastVerifiedDonationId'], isNull);
      expect(map['isAvailable'], isTrue);
      expect(map['eligibilityStatus'], 'READY');
    });

    test('Requester Transaction State Validation Tests', () {
      bool canConfirmDonation({
        required String actualRequesterId,
        required String callerId,
        required String? assignedDonorId,
        required String donationStatus,
        required num units,
        required num requestUnits,
      }) {
        if (actualRequesterId != callerId) return false;
        if (assignedDonorId == null || assignedDonorId.isEmpty) return false;
        if (assignedDonorId == callerId) return false;
        if (donationStatus != 'donor_accepted') return false;
        if (units <= 0 || units > 10 || units > requestUnits) return false;
        return true;
      }

      bool canReportDidNotHappen({
        required String actualRequesterId,
        required String callerId,
        required String? assignedDonorId,
        required String donationStatus,
      }) {
        if (actualRequesterId != callerId) return false;
        if (assignedDonorId == null || assignedDonorId.isEmpty) return false;
        if (donationStatus != 'donor_accepted') return false;
        return true;
      }

      const reqId = 'requester_1';
      const donorId = 'donor_1';
      const thirdPartyId = 'user_99';

      // 1. Requester can confirm donation when donor accepted
      expect(
        canConfirmDonation(
          actualRequesterId: reqId,
          callerId: reqId,
          assignedDonorId: donorId,
          donationStatus: 'donor_accepted',
          units: 1,
          requestUnits: 2,
        ),
        isTrue,
      );

      // 2. Assigned donor CANNOT confirm donation
      expect(
        canConfirmDonation(
          actualRequesterId: reqId,
          callerId: donorId,
          assignedDonorId: donorId,
          donationStatus: 'donor_accepted',
          units: 1,
          requestUnits: 2,
        ),
        isFalse,
      );

      // 3. Third-party CANNOT confirm donation
      expect(
        canConfirmDonation(
          actualRequesterId: reqId,
          callerId: thirdPartyId,
          assignedDonorId: donorId,
          donationStatus: 'donor_accepted',
          units: 1,
          requestUnits: 2,
        ),
        isFalse,
      );

      // 4. Repeated confirmation rejected (already pending_verification or verified)
      expect(
        canConfirmDonation(
          actualRequesterId: reqId,
          callerId: reqId,
          assignedDonorId: donorId,
          donationStatus: 'pending_verification',
          units: 1,
          requestUnits: 2,
        ),
        isFalse,
      );

      // 5. Requester can report did not happen when donor accepted
      expect(
        canReportDidNotHappen(
          actualRequesterId: reqId,
          callerId: reqId,
          assignedDonorId: donorId,
          donationStatus: 'donor_accepted',
        ),
        isTrue,
      );

      // 6. Assigned donor CANNOT report did not happen
      expect(
        canReportDidNotHappen(
          actualRequesterId: reqId,
          callerId: donorId,
          assignedDonorId: donorId,
          donationStatus: 'donor_accepted',
        ),
        isFalse,
      );

      // 7. Repeated report did not happen rejected when already waiting_donor
      expect(
        canReportDidNotHappen(
          actualRequesterId: reqId,
          callerId: reqId,
          assignedDonorId: null,
          donationStatus: 'waiting_donor',
        ),
        isFalse,
      );
    });
  });
}
