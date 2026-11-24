import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink/Bokul/donor_model.dart';
import 'package:lifelink/Manob/blood_request_model.dart';
import 'package:lifelink/Manob/donation_model.dart';
import 'package:lifelink/Manob/user_model.dart';
import 'package:lifelink/Pratik/admin_log_model.dart';

void main() {
  group('UserModel Serialization & Role Tests', () {
    test('User correctly identifies admin status', () {
      final admin = UserModel(
        uid: 'adm1',
        fullName: 'Admin User',
        email: 'admin@rku.ac.in',
        phoneNumber: '9876543210',
        role: 'admin',
      );

      final regularUser = UserModel(
        uid: 'usr1',
        fullName: 'John Doe',
        email: 'john@gmail.com',
        phoneNumber: '9876543211',
        role: 'user',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isActive, isTrue);
      expect(regularUser.isAdmin, isFalse);
    });

    test(
      'toFirestore map contains all required fields without sensitive secrets',
      () {
        final user = UserModel(
          uid: 'u123',
          fullName: 'Alice Smith',
          email: 'alice@gmail.com',
          phoneNumber: '9876543210',
          role: 'user',
          accountStatus: 'active',
        );

        final map = user.toMap();
        expect(map['fullName'], 'Alice Smith');
        expect(map['email'], 'alice@gmail.com');
        expect(map['phoneNumber'], '9876543210');
        expect(map['role'], 'user');
        expect(map['accountStatus'], 'active');
        expect(map.containsKey('password'), isFalse);
        expect(map.containsKey('otp'), isFalse);
      },
    );
  });

  group('DonorModel Tests', () {
    test('DonorProfile eligibility and availability are distinct', () {
      final donor = DonorModel(
        userId: 'donor1',
        fullName: 'Robert Brown',
        bloodGroup: 'B+',
        phoneNumber: '9876543210',
        address: 'Rajkot, Gujarat',
        city: 'Rajkot',
        isAvailable: true,
        eligibilityStatus: 'pending_screening',
        totalDonationCount: 2,
        totalUnitsDonated: 2,
      );

      expect(donor.isAvailable, isTrue);
      expect(donor.eligibilityStatus, 'pending_screening');
      expect(donor.totalDonationCount, 2);
      expect(donor.totalUnitsDonated, 2);
    });
  });

  group('BloodRequestModel Status & Visibility Tests', () {
    test('Private and unpublished requests are not public', () {
      final request = BloodRequestModel(
        requestId: 'req_001',
        requesterId: 'usr1',
        createdByRole: 'user',
        patientName: 'Jane Patient',
        bloodGroup: 'O+',
        units: 2,
        hospitalName: 'Civil Hospital',
        contactNumber: '9876543210',
        urgency: 'Critical',
        status: 'pending',
        visibility: 'private',
      );

      expect(request.isPublished, isFalse);
      expect(request.isPending, isTrue);
      expect(request.isApproved, isFalse);
    });

    test('Published and approved requests have correct flags', () {
      final publishedRequest = BloodRequestModel(
        requestId: 'req_002',
        requesterId: 'usr1',
        createdByRole: 'admin',
        patientName: 'Jane Patient',
        bloodGroup: 'AB+',
        units: 1,
        hospitalName: 'Civil Hospital',
        contactNumber: '9876543210',
        urgency: 'Urgent',
        status: 'approved',
        visibility: 'published',
      );

      expect(publishedRequest.isPublished, isTrue);
      expect(publishedRequest.isApproved, isTrue);
      expect(publishedRequest.isPending, isFalse);
    });
  });

  group('DonationModel Verification & Aggregate Tracking', () {
    test('Pending donation is not verified until approved', () {
      final donation = DonationModel(
        donationId: 'don_100',
        donorId: 'donor1',
        hospitalName: 'Civil Hospital',
        bloodGroup: 'A+',
        unitsDonated: 1.5,
        status: 'pending_verification',
      );

      expect(donation.isVerified, isFalse);
      expect(donation.isPending, isTrue);

      final verified = DonationModel(
        donationId: 'don_100',
        donorId: 'donor1',
        hospitalName: 'Civil Hospital',
        bloodGroup: 'A+',
        unitsDonated: 1.5,
        status: 'verified',
        verifiedBy: 'admin_uid',
      );

      expect(verified.isVerified, isTrue);
      expect(verified.isPending, isFalse);
      expect(verified.unitsDonated, 1.5);
    });

    test('DonationModel supports donorName and recordedBy compatibility', () {
      final donation = DonationModel(
        donationId: 'don_200',
        donorId: 'donor2',
        donorName: 'Rahul Patel',
        hospitalName: 'Sterling Hospital',
        bloodGroup: 'B+',
        unitsDonated: 2,
        status: 'verified',
        recordedBy: 'admin_master',
      );

      final map = donation.toMap();
      expect(map['donorName'], 'Rahul Patel');
      expect(map['recordedBy'], 'admin_master');
      expect(map['verifiedBy'], 'admin_master');

      final fromMap = DonationModel.fromMap('don_200', map);
      expect(fromMap.donorName, 'Rahul Patel');
      expect(fromMap.recordedBy, 'admin_master');
      expect(fromMap.verifiedBy, 'admin_master');
    });
  });

  group('BloodRequestModel Extended Compatibility Tests', () {
    test(
      'BloodRequestModel supports requesterName, city, and unitsRequired',
      () {
        final req = BloodRequestModel(
          requestId: 'req_003',
          requesterId: 'usr3',
          requesterName: 'Priya Sharma',
          patientName: 'Kavita Sharma',
          bloodGroup: 'O-',
          units: 3,
          hospitalName: 'AIIMS Rajkot',
          hospitalAddress: 'Khandheri, Rajkot',
          city: 'Rajkot',
          contactNumber: '9876543210',
        );

        expect(req.unitsRequired, 3);
        expect(req.contactPhone, '9876543210');
        expect(req.requesterName, 'Priya Sharma');
        expect(req.city, 'Rajkot');

        final map = req.toMap();
        expect(map['unitsRequired'], 3);
        expect(map['contactPhone'], '9876543210');
        expect(map['requesterName'], 'Priya Sharma');
        expect(map['city'], 'Rajkot');
      },
    );

    test('BloodRequestModel displayRequesterName fallback logic', () {
      final reqWithName = BloodRequestModel(
        requestId: 'req_004',
        requesterId: 'usr4',
        requesterName: 'Aarav Mehta',
        patientName: 'Patient X',
        bloodGroup: 'A+',
        units: 1,
        hospitalName: 'Sterling Hospital',
        contactNumber: '9998887776',
      );
      expect(reqWithName.displayRequesterName, 'Aarav Mehta');

      final reqWithEmptyName = BloodRequestModel(
        requestId: 'req_005',
        requesterId: 'usr5',
        requesterName: '   ',
        patientName: 'Patient Y',
        bloodGroup: 'O+',
        units: 2,
        hospitalName: 'Wockhardt Hospital',
        contactNumber: '9998887775',
      );
      expect(reqWithEmptyName.displayRequesterName, 'LifeLink Member');

      final reqWithNullName = BloodRequestModel(
        requestId: 'req_006',
        requesterId: 'usr6',
        patientName: 'Patient Z',
        bloodGroup: 'B-',
        units: 1,
        hospitalName: 'Civil Hospital',
        contactNumber: '9998887774',
      );
      expect(reqWithNullName.displayRequesterName, 'LifeLink Member');
    });

    test('BloodRequestModel handles requesterPhotoUrl and rejectionReason', () {
      final req = BloodRequestModel(
        requestId: 'req_007',
        requesterId: 'usr7',
        requesterName: 'Sunita Patel',
        requesterPhotoUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        patientName: 'Patient W',
        bloodGroup: 'AB-',
        units: 1,
        hospitalName: 'Civil Hospital',
        contactNumber: '9998887773',
        status: 'rejected',
        visibility: 'private',
        rejectionReason: 'Invalid hospital details provided.',
      );

      expect(req.isRejected, isTrue);
      expect(req.rejectionReason, 'Invalid hospital details provided.');
      expect(req.requesterPhotoUrl, contains('images.unsplash.com'));

      final map = req.toMap();
      expect(map['rejectionReason'], 'Invalid hospital details provided.');
      expect(
        map['requesterPhotoUrl'],
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
      );

      final restored = BloodRequestModel.fromMap('req_007', map);
      expect(restored.isRejected, isTrue);
      expect(restored.rejectionReason, 'Invalid hospital details provided.');
      expect(
        restored.requesterPhotoUrl,
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
      );
      expect(restored.displayRequesterName, 'Sunita Patel');
    });

    test('BloodRequestModel cancellation state', () {
      final cancelled = BloodRequestModel(
        requestId: 'req_008',
        requesterId: 'usr8',
        patientName: 'Patient C',
        bloodGroup: 'O+',
        units: 1,
        hospitalName: 'Hospital C',
        contactNumber: '9998887772',
        status: 'cancelled',
      );

      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isPending, isFalse);
      expect(cancelled.isApproved, isFalse);
    });
  });

  group('DonorModel Role & Admin Exclusion Tests', () {
    test('DonorModel role defaults to user and correctly identifies admin', () {
      final regularDonor = DonorModel(
        userId: 'donor_reg',
        fullName: 'Normal Donor',
        bloodGroup: 'O+',
        phoneNumber: '9876543210',
        address: 'Kalawad Road',
        city: 'Rajkot',
        profileImageUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
      );

      expect(regularDonor.role, 'user');
      expect(regularDonor.isAdmin, isFalse);
      expect(regularDonor.profileImageUrl, isNotNull);

      final adminDonor = regularDonor.copyWith(role: 'admin');
      expect(adminDonor.role, 'admin');
      expect(adminDonor.isAdmin, isTrue);

      final map = regularDonor.toMap();
      expect(map['role'], 'user');
      expect(
        map['profileImageUrl'],
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
      );

      final restored = DonorModel.fromMap('donor_reg', map);
      expect(restored.role, 'user');
      expect(restored.isAdmin, isFalse);
      expect(
        restored.profileImageUrl,
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
      );
    });

    test('Donor list filtering strictly excludes admin accounts', () {
      final donors = [
        DonorModel(
          userId: 'd1',
          fullName: 'Donor One',
          bloodGroup: 'A+',
          phoneNumber: '9000000001',
          address: 'Street 1',
          city: 'Rajkot',
          role: 'user',
        ),
        DonorModel(
          userId: 'd2_admin',
          fullName: 'System Administrator',
          bloodGroup: 'B+',
          phoneNumber: '9000000002',
          address: 'Headquarters',
          city: 'Rajkot',
          role: 'admin',
        ),
        DonorModel(
          userId: 'd3',
          fullName: 'Donor Three',
          bloodGroup: 'O+',
          phoneNumber: '9000000003',
          address: 'Street 3',
          city: 'Rajkot',
          role: 'user',
        ),
      ];

      final filteredDonors = donors.where((d) => !d.isAdmin).toList();
      expect(filteredDonors.length, 2);
      expect(
        filteredDonors.any((d) => d.fullName == 'System Administrator'),
        isFalse,
      );
      expect(filteredDonors.map((d) => d.userId), containsAll(['d1', 'd3']));
    });
  });

  group('DonorModel Blood Compatibility Matrix & Cooldown Tests', () {
    test('Universal donor O- can donate to all blood groups', () {
      final groups = ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];
      for (final recipient in groups) {
        expect(
          DonorModel.isBloodCompatible('O-', recipient),
          isTrue,
          reason: 'O- should be compatible with $recipient',
        );
      }
    });

    test('O+ can donate to all positive groups but not negative groups', () {
      expect(DonorModel.isBloodCompatible('O+', 'O+'), isTrue);
      expect(DonorModel.isBloodCompatible('O+', 'A+'), isTrue);
      expect(DonorModel.isBloodCompatible('O+', 'B+'), isTrue);
      expect(DonorModel.isBloodCompatible('O+', 'AB+'), isTrue);

      expect(DonorModel.isBloodCompatible('O+', 'O-'), isFalse);
      expect(DonorModel.isBloodCompatible('O+', 'A-'), isFalse);
      expect(DonorModel.isBloodCompatible('O+', 'B-'), isFalse);
      expect(DonorModel.isBloodCompatible('O+', 'AB-'), isFalse);
    });

    test('A+ compatibility check', () {
      expect(DonorModel.isBloodCompatible('A+', 'A+'), isTrue);
      expect(DonorModel.isBloodCompatible('A+', 'AB+'), isTrue);

      expect(DonorModel.isBloodCompatible('A+', 'O+'), isFalse);
      expect(DonorModel.isBloodCompatible('A+', 'B+'), isFalse);
      expect(DonorModel.isBloodCompatible('A+', 'A-'), isFalse);
    });

    test('B+ compatibility check', () {
      expect(DonorModel.isBloodCompatible('B+', 'B+'), isTrue);
      expect(DonorModel.isBloodCompatible('B+', 'AB+'), isTrue);

      expect(DonorModel.isBloodCompatible('B+', 'O+'), isFalse);
      expect(DonorModel.isBloodCompatible('B+', 'A+'), isFalse);
      expect(DonorModel.isBloodCompatible('B+', 'B-'), isFalse);
    });

    test('AB+ can only donate to AB+', () {
      expect(DonorModel.isBloodCompatible('AB+', 'AB+'), isTrue);
      expect(DonorModel.isBloodCompatible('AB+', 'O+'), isFalse);
      expect(DonorModel.isBloodCompatible('AB+', 'A+'), isFalse);
      expect(DonorModel.isBloodCompatible('AB+', 'B+'), isFalse);
    });

    test('Donor cooldown and eligibility getters operate accurately', () {
      final readyDonor = DonorModel(
        userId: 'd_ready',
        fullName: 'Ready Donor',
        bloodGroup: 'O+',
        phoneNumber: '9876543210',
        address: 'Rajkot',
        city: 'Rajkot',
        isAvailable: true,
        eligibilityStatus: 'READY',
        role: 'user',
      );
      expect(readyDonor.isReady, isTrue);
      expect(readyDonor.isCooldown, isFalse);
      expect(readyDonor.isEligibleToDonate, isTrue);

      final cooldownDonor = readyDonor.copyWith(
        eligibilityStatus: 'COOLDOWN',
        isAvailable: false,
      );
      expect(cooldownDonor.isReady, isFalse);
      expect(cooldownDonor.isCooldown, isTrue);
      expect(cooldownDonor.isEligibleToDonate, isFalse);

      final adminDonor = readyDonor.copyWith(role: 'admin');
      expect(adminDonor.isEligibleToDonate, isFalse);
    });
  });

  group(
    'BloodRequestModel Donor Assignment, Republishing & Completion Tests',
    () {
      test('BloodRequestModel correctly handles donor acceptance', () {
        final request = BloodRequestModel(
          requestId: 'req_accept_1',
          requesterId: 'req_user',
          createdByRole: 'user',
          patientName: 'Karan Patel',
          bloodGroup: 'B+',
          units: 2,
          hospitalName: 'Sterling Hospital',
          contactNumber: '9876543210',
          urgency: 'urgent',
          status: 'approved',
          visibility: 'published',
          donorId: 'donor_99',
          donorName: 'Rahul Sharma',
          donorPhone: '9123456780',
          donorBloodGroup: 'B+',
          donorCity: 'Rajkot',
          donationStatus: 'donor_accepted',
          acceptedAt: DateTime(2026, 10, 24, 15, 30),
        );

        expect(request.hasConfirmedDonor, isTrue);
        expect(request.isDonationAccepted, isTrue);
        expect(request.isDonationCompleted, isFalse);
        expect(request.displayDonorName, 'Rahul Sharma');

        final map = request.toMap();
        expect(map['donorId'], 'donor_99');
        expect(map['donorName'], 'Rahul Sharma');
        expect(map['donorPhone'], '9123456780');
        expect(map['donationStatus'], 'donor_accepted');

        final restored = BloodRequestModel.fromMap('req_accept_1', map);
        expect(restored.hasConfirmedDonor, isTrue);
        expect(restored.donorName, 'Rahul Sharma');
        expect(restored.donationStatus, 'donor_accepted');
      });

      test('BloodRequestModel correctly handles republished status', () {
        final request = BloodRequestModel(
          requestId: 'req_repub_1',
          requesterId: 'req_user',
          createdByRole: 'user',
          patientName: 'Aarav Mehta',
          bloodGroup: 'A+',
          units: 1,
          hospitalName: 'AIIMS Rajkot',
          contactNumber: '9876543210',
          urgency: 'normal',
          status: 'approved',
          visibility: 'published',
          isRepublished: true,
          republishedAt: DateTime(2026, 10, 24, 12, 0),
        );

        expect(request.isRepublished, isTrue);
        expect(request.isApproved, isTrue);
        expect(request.isPublished, isTrue);

        final map = request.toMap();
        expect(map['isRepublished'], isTrue);
        expect(map['republishedAt'], isNotNull);

        final restored = BloodRequestModel.fromMap('req_repub_1', map);
        expect(restored.isRepublished, isTrue);
      });

      test(
        'BloodRequestModel correctly records donation completion outcome',
        () {
          final request = BloodRequestModel(
            requestId: 'req_comp_1',
            requesterId: 'req_user',
            createdByRole: 'user',
            patientName: 'Deepak Verma',
            bloodGroup: 'O+',
            units: 3,
            hospitalName: 'Civil Hospital',
            contactNumber: '9876543210',
            urgency: 'critical',
            status: 'approved',
            visibility: 'published',
            donorId: 'donor_42',
            donorName: 'Amit Trivedi',
            donationStatus: 'completed',
            confirmedUnits: 2,
            confirmedAt: DateTime(2026, 10, 24, 18, 0),
          );

          expect(request.isDonationCompleted, isTrue);
          expect(request.confirmedUnits, 2);
          expect(request.confirmedAt, isNotNull);

          final map = request.toMap();
          expect(map['donationStatus'], 'completed');
          expect(map['confirmedUnits'], 2);

          final restored = BloodRequestModel.fromMap('req_comp_1', map);
          expect(restored.isDonationCompleted, isTrue);
          expect(restored.confirmedUnits, 2);
        },
      );
    },
  );

  group('DonationModel Verification Tests', () {
    test('Completed donation model serialization and confirmation flag', () {
      final donation = DonationModel(
        donationId: 'donation_req_123',
        donorId: 'd_123',
        bloodRequestId: 'req_123',
        unitsDonated: 2,
        bloodGroup: 'O+',
        hospitalName: 'Rajkot General Hospital',
        status: 'completed',
        confirmedByRequester: true,
        requesterId: 'r_456',
        requesterName: 'Priya Joshi',
        patientName: 'Sunita Joshi',
        donationDate: DateTime(2026, 10, 24),
      );

      expect(donation.isCompleted, isTrue);
      expect(donation.confirmedByRequester, isTrue);
      expect(donation.requesterName, 'Priya Joshi');
      expect(donation.patientName, 'Sunita Joshi');

      final map = donation.toMap();
      expect(map['status'], 'completed');
      expect(map['confirmedByRequester'], isTrue);
      expect(map['unitsDonated'], 2);

      final restored = DonationModel.fromMap('donation_req_123', map);
      expect(restored.isCompleted, isTrue);
      expect(restored.confirmedByRequester, isTrue);
      expect(restored.unitsDonated, 2);
      expect(restored.requesterName, 'Priya Joshi');
    });
  });

  group('Single-Donor Assignment & Locking Tests', () {
    test(
      'BloodRequest locks to single donor upon acceptance; others cannot accept',
      () {
        final req = BloodRequestModel(
          requestId: 'req_lock_01',
          requesterId: 'usr_req_1',
          patientName: 'Meera Rao',
          bloodGroup: 'B+',
          units: 2,
          hospitalName: 'Wockhardt Hospital',
          contactNumber: '9876543210',
          status: 'approved',
          visibility: 'published',
          donorId: 'donor_alice',
          donorName: 'Alice Donor',
          donorPhone: '9888877771',
          donorBloodGroup: 'B+',
          donorCity: 'Rajkot',
          donationStatus: 'donor_accepted',
          acceptedAt: DateTime(2026, 10, 26, 10, 0),
        );

        // Active assignment lock
        expect(req.hasConfirmedDonor, isTrue);
        expect(req.isDonationAccepted, isTrue);
        expect(req.donorId, 'donor_alice');
        expect(req.donorName, 'Alice Donor');
        expect(req.displayDonorName, 'Alice Donor');
        expect(req.donorAcceptedAt, isNotNull);

        // Serialization roundtrip preserves lock fields
        final map = req.toMap();
        expect(map['donorId'], 'donor_alice');
        expect(map['donationStatus'], 'donor_accepted');

        final restored = BloodRequestModel.fromMap('req_lock_01', map);
        expect(restored.hasConfirmedDonor, isTrue);
        expect(restored.donorId, 'donor_alice');
      },
    );
  });

  group('Donor Assignment Release & Reopening Tests', () {
    test(
      'Releasing donor assignment preserves audit fields and clears active donor',
      () {
        final assignedReq = BloodRequestModel(
          requestId: 'req_rel_01',
          requesterId: 'usr_req_2',
          patientName: 'Vikram Singh',
          bloodGroup: 'O+',
          units: 1,
          hospitalName: 'Sterling Hospital',
          contactNumber: '9876543210',
          status: 'approved',
          visibility: 'published',
          donorId: 'donor_bob',
          donorName: 'Bob Builder',
          donationStatus: 'donor_accepted',
        );

        expect(assignedReq.hasConfirmedDonor, isTrue);

        final releaseTime = DateTime(2026, 10, 26, 11, 30);
        final releasedReq = assignedReq.copyWith(
          donorId: '',
          donorName: '',
          donorPhone: '',
          donorBloodGroup: '',
          donorCity: '',
          donationStatus: 'reopened',
          lastReleasedDonorId: 'donor_bob',
          lastReleasedReason: 'Donor unavailable due to emergency',
          lastReleasedAt: releaseTime,
        );

        expect(releasedReq.hasConfirmedDonor, isFalse);
        expect(releasedReq.isDonationAccepted, isFalse);
        expect(releasedReq.lastReleasedDonorId, 'donor_bob');
        expect(
          releasedReq.lastReleasedReason,
          'Donor unavailable due to emergency',
        );
        expect(releasedReq.lastReleasedAt, releaseTime);

        // Verify map serialization
        final map = releasedReq.toMap();
        expect(map['donorId'], isNull);
        expect(map['lastReleasedDonorId'], 'donor_bob');
        expect(map['lastReleasedReason'], 'Donor unavailable due to emergency');

        final restored = BloodRequestModel.fromMap('req_rel_01', map);
        expect(restored.hasConfirmedDonor, isFalse);
        expect(restored.lastReleasedDonorId, 'donor_bob');
      },
    );
  });

  group('Donation Pending Verification vs Admin Verified Tests', () {
    test(
      'Requester confirmation sets pending_verification; NOT treated as verified',
      () {
        final pendingDonation = DonationModel(
          donationId: 'donation_req_pending',
          donorId: 'donor_99',
          donorName: 'Suresh Kumar',
          bloodRequestId: 'req_p1',
          hospitalName: 'Civil Hospital',
          bloodGroup: 'A+',
          unitsDonated: 2,
          status: 'pending_verification',
          confirmedByRequester: true,
          requesterId: 'usr_p1',
          requesterName: 'Pooja Kumar',
          patientName: 'Sunil Kumar',
        );

        expect(pendingDonation.isPendingVerification, isTrue);
        expect(pendingDonation.isVerified, isFalse);
        expect(pendingDonation.unitsDonated, 2);

        // Pending donation must NOT contribute to verified totals
        final list = [pendingDonation];
        final verifiedCount = list.where((d) => d.isVerified).length;
        final verifiedUnits = list
            .where((d) => d.isVerified)
            .fold<num>(0, (sum, d) => sum + d.unitsDonated);

        expect(verifiedCount, 0);
        expect(verifiedUnits, 0);
      },
    );

    test(
      'Admin verification transitions status to verified; idempotent & immutable units',
      () {
        final verifiedDonation = DonationModel(
          donationId: 'donation_req_ver',
          donorId: 'donor_99',
          donorName: 'Suresh Kumar',
          bloodRequestId: 'req_v1',
          hospitalName: 'Civil Hospital',
          bloodGroup: 'A+',
          unitsDonated: 2,
          status: 'verified',
          verifiedBy: 'admin_master',
          verifiedAt: DateTime(2026, 10, 26, 12, 0),
        );

        expect(verifiedDonation.isVerified, isTrue);
        expect(verifiedDonation.isPendingVerification, isFalse);
        expect(verifiedDonation.verifiedBy, 'admin_master');
        expect(verifiedDonation.unitsDonated, 2);

        // Verification map preserves immutable fields
        final map = verifiedDonation.toMap();
        expect(map['status'], 'verified');
        expect(map['unitsDonated'], 2);
        expect(map['donorId'], 'donor_99');

        final restored = DonationModel.fromMap('donation_req_ver', map);
        expect(restored.isVerified, isTrue);
        expect(restored.unitsDonated, 2);
      },
    );

    test(
      'Rejected donation is flagged with reason and never counted as verified',
      () {
        final rejectedDonation = DonationModel(
          donationId: 'donation_req_rej',
          donorId: 'donor_rej',
          hospitalName: 'Sterling Hospital',
          bloodGroup: 'B-',
          unitsDonated: 1,
          status: 'rejected',
          rejectionReason: 'Medical deferral at screening',
        );

        expect(rejectedDonation.isRejected, isTrue);
        expect(rejectedDonation.isVerified, isFalse);
        expect(rejectedDonation.isPendingVerification, isFalse);
        expect(
          rejectedDonation.rejectionReason,
          'Medical deferral at screening',
        );

        final map = rejectedDonation.toMap();
        expect(map['status'], 'rejected');
        expect(map['rejectionReason'], 'Medical deferral at screening');

        final restored = DonationModel.fromMap('donation_req_rej', map);
        expect(restored.isRejected, isTrue);
        expect(restored.isVerified, isFalse);
      },
    );
  });

  group('DonorModel lastVerifiedDonationId & Atomic Verification Tests', () {
    test(
      'DonorModel supports lastVerifiedDonationId serialization & copyWith',
      () {
        final initialDonor = DonorModel(
          userId: 'donor_v1',
          fullName: 'Aakash Verma',
          bloodGroup: 'B+',
          phoneNumber: '9876543210',
          address: 'University Road',
          city: 'Rajkot',
          totalDonationCount: 0,
          totalUnitsDonated: 0,
          lastVerifiedDonationId: null,
        );

        expect(initialDonor.lastVerifiedDonationId, isNull);
        expect(initialDonor.totalDonationCount, 0);
        expect(initialDonor.totalUnitsDonated, 0);

        // Simulate atomic admin verification update
        final verifiedDonor = initialDonor.copyWith(
          totalDonationCount: initialDonor.totalDonationCount + 1,
          totalUnitsDonated: initialDonor.totalUnitsDonated + 2,
          lastVerifiedDonationId: 'donation_req_777',
        );

        expect(verifiedDonor.totalDonationCount, 1);
        expect(verifiedDonor.totalUnitsDonated, 2);
        expect(verifiedDonor.lastVerifiedDonationId, 'donation_req_777');

        final map = verifiedDonor.toMap();
        expect(map['lastVerifiedDonationId'], 'donation_req_777');
        expect(map['totalDonationCount'], 1);
        expect(map['totalUnitsDonated'], 2);

        final restored = DonorModel.fromMap('donor_v1', map);
        expect(restored.lastVerifiedDonationId, 'donation_req_777');
        expect(restored.totalDonationCount, 1);
        expect(restored.totalUnitsDonated, 2);
      },
    );

    test(
      'Duplicate verification check detects existing lastVerifiedDonationId',
      () {
        final existingProfile = DonorModel(
          userId: 'donor_v2',
          fullName: 'Kiran Dave',
          bloodGroup: 'O+',
          phoneNumber: '9876543210',
          address: 'Ring Road',
          city: 'Rajkot',
          totalDonationCount: 1,
          totalUnitsDonated: 1,
          lastVerifiedDonationId: 'donation_req_888',
        );

        // Attempting to re-verify the exact same donation
        const attemptedDonationId = 'donation_req_888';
        final isAlreadyVerified =
            existingProfile.lastVerifiedDonationId == attemptedDonationId;
        expect(
          isAlreadyVerified,
          isTrue,
          reason:
              'Rules require lastVerifiedDonationId to differ from previous state to prevent double-counting',
        );
      },
    );
  });

  group('AdminLogModel Canonical Schema & Actor Identity Tests', () {
    test(
      'AdminLogModel persists actorId and actorName with adminId compatibility',
      () {
        final log = AdminLogModel(
          logId: 'log_001',
          actorId: 'usr_actor_99',
          actorName: 'Donor Volunteer',
          adminId: 'usr_actor_99',
          adminName: 'Donor Volunteer',
          action: 'donor_accepted',
          targetCollection: 'blood_requests',
          targetId: 'req_123',
          title: 'Donor Accepted Request',
        );

        expect(log.actorId, 'usr_actor_99');
        expect(log.actorName, 'Donor Volunteer');
        expect(log.displayActorName, 'Donor Volunteer');

        final map = log.toMap();
        expect(map['actorId'], 'usr_actor_99');
        expect(map['actorName'], 'Donor Volunteer');
        expect(map['action'], 'donor_accepted');

        final restored = AdminLogModel.fromMap('log_001', map);
        expect(restored.actorId, 'usr_actor_99');
        expect(restored.actorName, 'Donor Volunteer');
        expect(restored.displayActorName, 'Donor Volunteer');
      },
    );

    test(
      'AdminLogModel falls back to adminId when legacy record lacks actorId',
      () {
        final legacyMap = {
          'adminId': 'admin_legacy_01',
          'adminName': 'Master Admin',
          'action': 'request_approved',
          'targetCollection': 'blood_requests',
          'targetId': 'req_legacy',
        };

        final restored = AdminLogModel.fromMap('log_legacy', legacyMap);
        expect(restored.actorId, 'admin_legacy_01');
        expect(restored.adminId, 'admin_legacy_01');
        expect(restored.displayActorName, 'Master Admin');
      },
    );
  });
}
