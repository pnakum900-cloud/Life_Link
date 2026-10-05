
import 'package:flutter/material.dart';
import 'donor_profile.dart';
import 'user_nav.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _locationController = TextEditingController(
    text: '150 Feet Ring Road',
  );

  final List<Map<String, String>> _donors = const [
    {
      'name': 'Pratik Nakum',
      'address': '150 Feet Ring Road, Rajkot',
      'status': 'AVAILABLE',
      'mobile': '9876543210',
    },
    {
      'name': 'Pratik Nakum',
      'address': '150 Feet Ring Road, Rajkot',
      'status': 'AVAILABLE',
      'mobile': '9876543211',
    },
    {
      'name': 'Pratik Nakum',
      'address': '150 Feet Ring Road, Rajkot',
      'status': 'AVAILABLE',
      'mobile': '9876543212',
    },
    {
      'name': 'Pratik Nakum',
      'address': '150 Feet Ring Road, Rajkot',
      'status': 'AVAILABLE',
      'mobile': '9876543213',
    },
    {
      'name': 'Bokul Bormon',
      'address': '150 Feet Ring Road, Rajkot',
      'status': 'AVAILABLE',
      'mobile': '9876543214',
    },
    {
      'name': 'Karan Patel',
      'address': 'Kalawad Road, Rajkot',
      'status': 'AVAILABLE',
      'mobile': '9876543215',
    },
    {
      'name': 'Neha Shah',
      'address': 'University Road, Rajkot',
      'status': 'AVAILABLE',
      'mobile': '9876543216',
    },
  ];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredDonors {
    final query = _locationController.text.trim().toLowerCase();

    if (query.isEmpty) return _donors;

    return _donors.where((donor) {
      return donor['name']!.toLowerCase().contains(query) ||
          donor['address']!.toLowerCase().contains(query);
    }).toList();
  }

  void _showDonorDetails(Map<String, String> donor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Donor Details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: kUserDark,
            ),
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
                donor['name']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kUserDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mobile Number',
                style: TextStyle(
                  fontSize: 13,
                  color: kUserMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                donor['mobile']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kUserDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: kUserBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final donors = _filteredDonors;

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
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: TextField(
                controller: _locationController,
                onChanged: (_) => setState(() {}),
                decoration: userFieldDecoration(
                  '150 Feet Ring Road',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: kUserBlue,
                  ),
                ),
              ),
            ),
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
                  ? const Center(
                      child: Text('No donors found'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        20,
                      ),
                      itemCount: donors.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final donor = donors[index];

                        return _DonorCard(
                          donor: donor,
                          onOpen: () {
                            _showDonorDetails(donor);
                          },
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
  });

  final Map<String, String> donor;
  final VoidCallback onOpen;

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
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: kUserDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        donor['address']!,
                        style: const TextStyle(
                          color: kUserMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
                    color: const Color(0xFFBBF7D0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'AVAILABLE',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),

                // Only arrow button remains
                IconButton(
                  onPressed: onOpen,
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: kUserBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
