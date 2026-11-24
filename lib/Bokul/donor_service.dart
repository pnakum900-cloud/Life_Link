import 'package:cloud_firestore/cloud_firestore.dart';
import '../Manob/app_validators.dart';
import '../Manob/firebase_service.dart';
import '../Pratik/admin_service.dart';
import 'donor_model.dart';

class DonorService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final CollectionReference _donorsCol = _firestore.collection(
    'donor_profiles',
  );

  /// Gets a donor profile document by user ID.
  static Future<DonorModel?> getDonorProfile(String userId) async {
    try {
      final doc = await _donorsCol.doc(userId).get();
      if (!doc.exists) return null;
      return DonorModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Streams a single donor profile for real-time updates.
  static Stream<DonorModel?> streamDonorProfile(String userId) {
    return _donorsCol.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DonorModel.fromFirestore(doc);
    });
  }

  /// Streams donors with optional blood group filter (for search and admin panel).
  /// Strictly filters out admin accounts and inactive/suspended accounts so only active donors appear.
  /// Sorts in memory to avoid requiring Firestore composite indexes.
  static Stream<List<DonorModel>> streamDonors({String? bloodGroup}) {
    Query query = _donorsCol;

    if (bloodGroup != null &&
        bloodGroup.isNotEmpty &&
        bloodGroup != 'All Donors') {
      query = query.where('bloodGroup', isEqualTo: bloodGroup);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DonorModel.fromFirestore(doc))
          .where(
            (donor) =>
                !donor.isAdmin &&
                donor.eligibilityStatus != 'SUSPENDED' &&
                donor.eligibilityStatus != 'DISABLED',
          )
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  /// Searches donors by query (matching name, address, or blood group).
  /// Strictly excludes admin accounts and inactive/suspended accounts.
  static Future<List<DonorModel>> searchDonors({
    String? locationQuery,
    String? bloodGroup,
    bool onlyAvailable = false,
  }) async {
    try {
      Query query = _donorsCol;

      if (bloodGroup != null &&
          bloodGroup.isNotEmpty &&
          bloodGroup != 'All Donors') {
        query = query.where('bloodGroup', isEqualTo: bloodGroup);
      }

      final snapshot = await query.get();
      var list = snapshot.docs
          .map((doc) => DonorModel.fromFirestore(doc))
          .where(
            (donor) =>
                !donor.isAdmin &&
                donor.eligibilityStatus != 'SUSPENDED' &&
                donor.eligibilityStatus != 'DISABLED',
          )
          .toList();

      if (onlyAvailable) {
        list = list.where((d) => d.isAvailable).toList();
      }

      if (locationQuery != null && locationQuery.trim().isNotEmpty) {
        final q = locationQuery.trim().toLowerCase();
        list = list.where((d) {
          return d.fullName.toLowerCase().contains(q) ||
              d.address.toLowerCase().contains(q) ||
              d.city.toLowerCase().contains(q) ||
              d.bloodGroup.toLowerCase().contains(q);
        }).toList();
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  /// Updates editable donor profile fields and synchronizes with user profile.
  /// Regular users CANNOT change blood group.
  /// Only administrators can change blood group (requires [isAdmin] == true).
  static Future<bool> updateDonorProfile(
    String userId, {
    String? fullName,
    String? bloodGroup,
    String? phoneNumber,
    String? address,
    String? city,
    bool? isAvailable,
    String? eligibilityStatus,
    String? profileImageUrl,
    bool isAdmin = false,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (fullName != null) updates['fullName'] = fullName.trim();
      // Enforce: ONLY administrators can change bloodGroup!
      if (bloodGroup != null && isAdmin) {
        final validatedGroup = bloodGroup.trim().toUpperCase();
        if (AppValidators.validBloodGroups.contains(validatedGroup)) {
          updates['bloodGroup'] = validatedGroup;
        }
      }
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();
      if (address != null) updates['address'] = address.trim();
      if (city != null) updates['city'] = AppValidators.resolveCity(city);
      if (isAvailable != null) updates['isAvailable'] = isAvailable;
      if (eligibilityStatus != null) {
        updates['eligibilityStatus'] = eligibilityStatus;
      }
      if (profileImageUrl != null) {
        updates['profileImageUrl'] = profileImageUrl;
      }

      await _donorsCol.doc(userId).update(updates);

      // Sync name, phone & photo with user document
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userUpdates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (fullName != null) {
          userUpdates['fullName'] = fullName.trim();
        }
        if (phoneNumber != null) {
          userUpdates['phoneNumber'] = phoneNumber.trim();
        }
        if (profileImageUrl != null) {
          userUpdates['profileImageUrl'] = profileImageUrl;
        }
        await userRef.update(userUpdates);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cascades deletion through all related donor & user data (requests, donations, tokens, etc.).
  static Future<bool> deleteDonor(
    String userId, {
    String adminId = 'admin_system',
    String? adminName,
  }) async {
    final res = await AdminService.cascadeDeleteUser(
      userId,
      adminId: adminId,
      adminName: adminName,
    );
    return res.success;
  }
}
