import '../Manob/user_model.dart';
import 'donor_model.dart';

/// Legacy holder updated dynamically from Firestore.
/// Retained for backward-compatibility while all screens
/// have been migrated to use direct Firestore streams and services.
class UserProfileData {
  static String name = '';
  static String mobile = '';
  static String bloodGroup = 'O+';
  static String address = '';
  static String lastDonation = 'Never';
  static String totalDonations = '0 Times';
  static String eligibility = 'READY';

  /// Synchronizes static fields with active user & donor models.
  static void syncFromModels({UserModel? user, DonorModel? donor}) {
    if (user != null) {
      name = user.fullName;
      mobile = user.phoneNumber;
    }
    if (donor != null) {
      if (donor.fullName.isNotEmpty) name = donor.fullName;
      if (donor.phoneNumber.isNotEmpty) mobile = donor.phoneNumber;
      bloodGroup = donor.bloodGroup;
      address = donor.address;
      eligibility = donor.eligibilityStatus;
      totalDonations = '${donor.totalDonationCount} Times';
      if (donor.lastDonationAt != null) {
        lastDonation =
            '${donor.lastDonationAt!.day}/${donor.lastDonationAt!.month}/${donor.lastDonationAt!.year}';
      }
    }
  }
}
