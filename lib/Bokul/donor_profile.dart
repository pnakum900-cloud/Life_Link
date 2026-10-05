
import 'package:flutter/material.dart';
import 'request.dart';
import 'user_data.dart';
import 'user_nav.dart';

class DonorProfile extends StatefulWidget {
  const DonorProfile({
    super.key,
    this.name,
    this.address,
    this.bloodGroup,
  });

  final String? name;
  final String? address;
  final String? bloodGroup;

  @override
  State<DonorProfile> createState() => _DonorProfileState();
}

class _DonorProfileState extends State<DonorProfile> {
  late String donorBlood;
  String eligibility = 'READY';

  static const List<String> bloodOptions = [
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
  void initState() {
    super.initState();

    donorBlood =
        widget.bloodGroup ?? UserProfileData.bloodGroup;
  }

  void _showBloodGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedBlood = donorBlood;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Change Blood Group',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kUserDark,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: bloodOptions.map((group) {
                  return RadioListTile<String>(
                    title: Text(group),
                    value: group,
                    groupValue: selectedBlood,
                    activeColor: kUserBlue,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedBlood = value;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      donorBlood = selectedBlood;
                    });
                    Navigator.pop(context);
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

  void _showEligibilityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedEligibility = eligibility;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Eligibility',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kUserDark,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('READY'),
                    value: 'READY',
                    groupValue: selectedEligibility,
                    activeColor: kUserBlue,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedEligibility = value;
                        });
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('NOT READY'),
                    value: 'NOT READY',
                    groupValue: selectedEligibility,
                    activeColor: kUserBlue,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedEligibility = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      eligibility = selectedEligibility;
                    });
                    Navigator.pop(context);
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
    final donorName =
        widget.name ?? UserProfileData.name;
    final donorAddress =
        widget.address ?? UserProfileData.address;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const UserBottomBar(currentIndex: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                    ),
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

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kUserBorder,
                    width: 2,
                  ),
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                donorName,
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
                      donorAddress,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kUserMuted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showBloodGroupDialog,
                      child: _InfoCard(
                        label: 'BLOOD GROUP',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFECACA),
                            borderRadius:
                                BorderRadius.circular(16),
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
                      onTap: _showEligibilityDialog,
                      child: _InfoCard(
                        label: 'ELIGIBILITY',
                        child: eligibility == 'READY'
                            ? const _GreenBadge(
                                text: 'READY',
                              )
                            : const _RedBadge(
                                text: 'NOT READY',
                              ),
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
                      label: 'Last Donation',
                      child: Text(
                        UserProfileData.lastDonation,
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
                      label: 'TOTAL',
                      child: Text(
                        UserProfileData.totalDonations,
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
                        builder: (context) =>
                            const Request(),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.child,
  });

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
  const _GreenBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
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
  const _RedBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
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
