import 'package:flutter/material.dart';
import '../Manob/auth_service.dart';
import 'donor_model.dart';
import 'donor_service.dart';
import 'request.dart';
import 'user_data.dart';
import 'user_nav.dart';

class DonorProfile extends StatefulWidget {
  final String? userId;
  final String? name;
  final String? address;
  final String? bloodGroup;

  const DonorProfile({
    super.key,
    this.userId,
    this.name,
    this.address,
    this.bloodGroup,
  });

  @override
  State<DonorProfile> createState() => _DonorProfileState();
}

class _DonorProfileState extends State<DonorProfile> {
  late String _activeUserId;

  @override
  void initState() {
    super.initState();
    _activeUserId =
        widget.userId ?? AuthService.currentFirebaseUser?.uid ?? 'current_user';
  }

  void _showBloodGroupLockedInfo(String currentBlood) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock, color: Color(0xFFDC2626), size: 22),
              SizedBox(width: 8),
              Text(
                'Blood Group Locked',
                style: TextStyle(fontWeight: FontWeight.w700, color: kUserDark),
              ),
            ],
          ),
          content: Text(
            'Your blood group is registered as $currentBlood.\n\nTo ensure recipient safety and clinical accuracy, regular users cannot alter their blood group after registration.\n\nPlease contact a LifeLink administrator if your blood group needs correction.',
            style: const TextStyle(fontSize: 14, color: kUserDark, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'UNDERSTOOD',
                style: TextStyle(color: kUserBlue, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEligibilityDialog(String currentEligibility) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedEligibility = currentEligibility;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Eligibility & Availability',
                style: TextStyle(fontWeight: FontWeight.w700, color: kUserDark),
              ),
              content: RadioGroup<String>(
                groupValue: selectedEligibility,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedEligibility = value;
                    });
                  }
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text('READY'),
                      value: 'READY',
                      activeColor: kUserBlue,
                    ),
                    RadioListTile<String>(
                      title: Text('NOT READY'),
                      value: 'NOT READY',
                      activeColor: kUserBlue,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await DonorService.updateDonorProfile(
                      _activeUserId,
                      eligibilityStatus: selectedEligibility,
                      isAvailable: selectedEligibility == 'READY',
                    );
                    UserProfileData.eligibility = selectedEligibility;
                  },
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      color: kUserBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.currentFirebaseUser?.uid;
    final isOwnProfile = _activeUserId == currentUid;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const UserBottomBar(currentIndex: 4),
      body: SafeArea(
        child: StreamBuilder<DonorModel?>(
          stream: DonorService.streamDonorProfile(_activeUserId),
          builder: (context, snapshot) {
            final donor = snapshot.data;

            final donorName = donor?.fullName.isNotEmpty == true
                ? donor!.fullName
                : (widget.name ?? UserProfileData.name);

            final donorAddress = donor?.address.isNotEmpty == true
                ? '${donor!.address}, ${donor.city}'
                : (widget.address ?? UserProfileData.address);

            final donorBlood =
                donor?.bloodGroup ??
                widget.bloodGroup ??
                UserProfileData.bloodGroup;

            final eligibility =
                donor?.eligibilityStatus ?? UserProfileData.eligibility;

            final lastDonation = donor?.lastDonationAt != null
                ? '${donor!.lastDonationAt!.day}/${donor.lastDonationAt!.month}/${donor.lastDonationAt!.year}'
                : UserProfileData.lastDonation;

            final totalDonations = donor != null
                ? '${donor.totalDonationCount} Times'
                : UserProfileData.totalDonations;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        color: kUserBlue,
                      ),
                      const Expanded(
                        child: Text(
                          'Donor Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kUserBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RequesterAvatar(
                    userId: _activeUserId,
                    photoUrl: donor?.profileImageUrl,
                    name: donorName,
                    size: 108,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    donorName.isNotEmpty ? donorName : 'Donor Profile',
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
                      const Icon(Icons.location_on, size: 16, color: kUserBlue),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          donorAddress.isNotEmpty
                              ? donorAddress
                              : 'Rajkot, Gujarat',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: kUserMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showBloodGroupLockedInfo(donorBlood),
                          child: _InfoCard(
                            label: 'BLOOD GROUP',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFECACA),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                donorBlood,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: isOwnProfile
                              ? () => _showEligibilityDialog(eligibility)
                              : null,
                          child: _InfoCard(
                            label: 'ELIGIBILITY',
                            child: eligibility.toUpperCase() == 'READY'
                                ? const _GreenBadge(text: 'READY')
                                : const _RedBadge(text: 'NOT READY'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          label: 'LAST DONATION',
                          child: Text(
                            lastDonation,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: kUserDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          label: 'TOTAL DONATIONS',
                          child: Text(
                            totalDonations,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: kUserMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Request(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kUserBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'REQUEST BLOOD',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              color: kUserMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          child,
          const Spacer(),
        ],
      ),
    );
  }
}

class _GreenBadge extends StatelessWidget {
  const _GreenBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFBBF7D0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF15803D),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RedBadge extends StatelessWidget {
  const _RedBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFECACA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB91C1C),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
