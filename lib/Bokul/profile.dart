import 'package:flutter/material.dart';
import '../Manob/auth_service.dart';
import '../Manob/login_screen.dart';
import '../Manob/user_model.dart';
import 'donation_history.dart';
import 'donor_model.dart';
import 'donor_profile.dart';
import 'donor_service.dart';
import 'edit_profile.dart';
import 'user_data.dart';
import 'user_nav.dart';
import 'user_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService.logout();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
                Navigator.pushAndRemoveUntil(
                  this.context,
                  MaterialPageRoute(builder: (context) => const UserLogin()),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAuthUser = AuthService.currentFirebaseUser;
    final uid = currentAuthUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const UserBottomBar(currentIndex: 4),
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: UserService.streamUser(uid),
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;

            return StreamBuilder<DonorModel?>(
              stream: DonorService.streamDonorProfile(uid),
              builder: (context, donorSnapshot) {
                final donor = donorSnapshot.data;

                // Sync legacy holder
                UserProfileData.syncFromModels(user: user, donor: donor);

                final displayName = user?.fullName.isNotEmpty == true
                    ? user!.fullName
                    : (currentAuthUser?.displayName ?? 'Blood Donor');

                final displayAddress = donor?.address.isNotEmpty == true
                    ? donor!.address
                    : 'Rajkot, Gujarat';

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    children: [
                      LifeLinkHeader(onProfileTap: () {}),
                      UserAvatar(
                        size: 108,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfile(),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kUserDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: kUserBlue,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayAddress.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: kUserMuted,
                                fontSize: 12,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfile(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kUserDark,
                            side: const BorderSide(color: kUserBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Edit Profile  >'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DonationHistory(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 120,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: kUserBorder),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Donation History',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: kUserDark,
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      'View verified records',
                                      style: TextStyle(
                                        color: kUserMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DonorProfile(
                                      userId: uid,
                                      name: displayName,
                                      address: displayAddress,
                                      bloodGroup: donor?.bloodGroup,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 120,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: kUserBorder),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Donor Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: kUserDark,
                                      ),
                                    ),
                                    const Spacer(),
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFDBEAFE),
                                      child: Text(
                                        donor?.bloodGroup ?? 'O+',
                                        style: const TextStyle(
                                          color: kUserBlue,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFECACA),
                            foregroundColor: const Color(0xFFB91C1C),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'LOGOUT',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
