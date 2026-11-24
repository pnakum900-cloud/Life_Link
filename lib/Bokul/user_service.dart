import 'package:cloud_firestore/cloud_firestore.dart';
import '../Manob/firebase_service.dart';
import '../Manob/user_model.dart';
import '../Pratik/admin_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final CollectionReference _usersCol = _firestore.collection('users');

  /// Gets a single user profile document by UID.
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Streams a single user profile document for real-time updates.
  static Stream<UserModel?> streamUser(String uid) {
    return _usersCol.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Streams all registered users (for admin panel).
  static Stream<List<UserModel>> streamAllUsers() {
    return _usersCol.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  /// Updates allowed profile fields safely without overwriting unrelated data.
  static Future<bool> updateUserProfile(
    String uid, {
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (fullName != null) updates['fullName'] = fullName.trim();
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _usersCol.doc(uid).update(updates);

      // Also sync fullName, phoneNumber, and profileImageUrl to donor_profiles if it exists
      final donorRef = _firestore.collection('donor_profiles').doc(uid);
      final donorDoc = await donorRef.get();
      if (donorDoc.exists) {
        final donorUpdates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (fullName != null) {
          donorUpdates['fullName'] = fullName.trim();
        }
        if (phoneNumber != null) {
          donorUpdates['phoneNumber'] = phoneNumber.trim();
        }
        if (profileImageUrl != null) {
          donorUpdates['profileImageUrl'] = profileImageUrl;
        }
        await donorRef.update(donorUpdates);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Saves the user's compressed device profile photo to a dedicated 'profile_photos' collection.
  /// Validates both raw string length and byte size to preserve ₹0 free tier constraints.
  /// Avoids duplicating massive Base64 strings into 'users' or 'donor_profiles'.
  static Future<bool> saveProfilePhoto(
    String uid, {
    required String photoData,
    required int sizeBytes,
  }) async {
    try {
      // Validate actual photoData string length and raw byte size
      if (photoData.length > 410000 || sizeBytes > 307200) {
        throw Exception(
          'Photo size exceeds the 300 KiB document safety limit.',
        );
      }

      final photoDocRef = _firestore.collection('profile_photos').doc(uid);
      await photoDocRef.set({
        'userId': uid,
        'photoData': photoData,
        'sizeBytes': sizeBytes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear any legacy duplicated image strings from users and donor_profiles
      // so photo display is synchronized reactively from the dedicated profile_photos collection
      await updateUserProfile(uid, profileImageUrl: '');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Removes the user's profile photo from 'profile_photos', 'users', and 'donor_profiles'.
  static Future<bool> removeProfilePhoto(String uid) async {
    try {
      await _firestore.collection('profile_photos').doc(uid).delete();
      await updateUserProfile(uid, profileImageUrl: '');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Streams the user's profile photo from the dedicated 'profile_photos' collection in real time.
  static Stream<String?> streamUserProfilePhoto(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _firestore.collection('profile_photos').doc(uid).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      final data = doc.data();
      final photoData = data?['photoData'];
      return photoData is String ? photoData : null;
    });
  }

  /// Admin method to update user status and basic profile info.
  /// Enforces field-limited profile management.
  static Future<bool> adminUpdateUser(
    String uid, {
    String? role,
    String? accountStatus,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (accountStatus != null) updates['accountStatus'] = accountStatus;
      if (fullName != null) updates['fullName'] = fullName.trim();
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();

      await _usersCol.doc(uid).update(updates);

      // Synchronize donor availability and eligibility on suspension/activation
      final donorRef = _firestore.collection('donor_profiles').doc(uid);
      final donorDoc = await donorRef.get();
      if (donorDoc.exists) {
        if (accountStatus == 'suspended' || accountStatus == 'disabled') {
          await donorRef.update({
            'isAvailable': false,
            'eligibilityStatus': 'SUSPENDED',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (accountStatus == 'active') {
          await donorRef.update({
            'isAvailable': true,
            'eligibilityStatus': 'READY',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cascades deletion through all related user data (requests, donations, tokens, notifications, etc.).
  static Future<bool> deleteUser(
    String uid, {
    String adminId = 'admin_system',
    String? adminName,
  }) async {
    final res = await AdminService.cascadeDeleteUser(
      uid,
      adminId: adminId,
      adminName: adminName,
    );
    return res.success;
  }
}
