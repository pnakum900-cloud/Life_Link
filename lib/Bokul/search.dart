import 'package:flutter/material.dart';
import '../Manob/auth_service.dart';
import 'donor_model.dart';
import 'donor_profile.dart';
import 'donor_service.dart';
import 'user_nav.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _locationController = TextEditingController();
  String _selectedBloodGroup = 'All';

  static const List<String> _bloodGroups = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _showDonorDetails(DonorModel donor) {
    final currentUid = AuthService.currentFirebaseUser?.uid;
    final isPrivileged = currentUid != null && currentUid == donor.userId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Donor Details',
            style: TextStyle(fontWeight: FontWeight.w700, color: kUserDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Name',
                style: TextStyle(
                  fontSize: 13,
                  color: kUserMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                donor.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kUserDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Blood Group',
                style: TextStyle(
                  fontSize: 13,
                  color: kUserMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                donor.bloodGroup,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kUserBlue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Contact Number',
                style: TextStyle(
                  fontSize: 13,
                  color: kUserMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPrivileged
                    ? (donor.phoneNumber.isNotEmpty
                          ? donor.phoneNumber
                          : 'Not provided')
                    : 'Protected (shared upon request acceptance)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrivileged ? kUserDark : kUserMuted,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 13,
                  color: kUserMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPrivileged ? '${donor.address}, ${donor.city}' : donor.city,
                style: const TextStyle(fontSize: 14, color: kUserDark),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: kUserBlue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: const UserBottomBar(currentIndex: 1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: LifeLinkHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _locationController,
                onChanged: (_) => setState(() {}),
                decoration:
                    userFieldDecoration(
                      'Search by location (e.g. 150 Feet Ring Road)...',
                    ).copyWith(
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: kUserBlue,
                      ),
                    ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: _bloodGroups.map((group) {
                  final isSelected = _selectedBloodGroup == group;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(group),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedBloodGroup = group;
                        });
                      },
                      selectedColor: const Color(0xFFDBEAFE),
                      labelStyle: TextStyle(
                        color: isSelected ? kUserBlue : kUserDark,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? kUserBlue : kUserBorder,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<DonorModel>>(
                stream: DonorService.streamDonors(
                  bloodGroup: _selectedBloodGroup == 'All'
                      ? null
                      : _selectedBloodGroup,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allDonors = snapshot.data ?? [];
                  final query = _locationController.text.trim().toLowerCase();

                  final donors = allDonors.where((donor) {
                    final matchesQuery =
                        query.isEmpty ||
                        donor.fullName.toLowerCase().contains(query) ||
                        donor.address.toLowerCase().contains(query) ||
                        donor.city.toLowerCase().contains(query) ||
                        donor.bloodGroup.toLowerCase().contains(query);
                    return matchesQuery;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: Text(
                          '${donors.length} Donors found in Rajkot',
                          style: const TextStyle(
                            color: kUserMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: donors.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search_off_outlined,
                                      size: 48,
                                      color: kUserHint,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No donors found matching criteria.',
                                      style: TextStyle(
                                        color: kUserMuted,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  20,
                                ),
                                itemCount: donors.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final donor = donors[index];
                                  return _DonorCard(
                                    donor: donor,
                                    onOpen: () => _showDonorDetails(donor),
                                    onViewProfile: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DonorProfile(
                                            userId: donor.userId,
                                            name: donor.fullName,
                                            address: donor.address,
                                            bloodGroup: donor.bloodGroup,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  const _DonorCard({
    required this.donor,
    required this.onOpen,
    required this.onViewProfile,
  });

  final DonorModel donor;
  final VoidCallback onOpen;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kUserBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RequesterAvatar(
                  userId: donor.userId,
                  photoUrl: donor.profileImageUrl,
                  name: donor.fullName,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: kUserDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        donor.city,
                        style: const TextStyle(color: kUserMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Text(
                    donor.bloodGroup,
                    style: const TextStyle(
                      color: kUserBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: donor.isAvailable
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    donor.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
                    style: TextStyle(
                      color: donor.isAvailable
                          ? const Color(0xFF15803D)
                          : const Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.arrow_forward, color: kUserBlue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
