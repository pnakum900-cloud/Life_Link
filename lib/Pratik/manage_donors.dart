import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Bokul/donor_model.dart';
import '../Bokul/donor_service.dart';
import '../Bokul/user_nav.dart';
import '../Manob/app_validators.dart';
import '../Manob/auth_service.dart';
import 'admin_data.dart';
import 'admin_nav.dart';
import 'admin_service.dart';
import 'admin_theme.dart';

class ManageDonors extends StatefulWidget {
  const ManageDonors({super.key});

  @override
  State<ManageDonors> createState() => _ManageDonorsState();
}

class _ManageDonorsState extends State<ManageDonors> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All Donors';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(DonorModel donor) async {
    final adminUser = AuthService.currentFirebaseUser;
    if (donor.userId == adminUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own administrator account.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (donor.role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Administrators cannot be deleted through donor management.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Permanent Action Warning',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is PERMANENT and CANNOT be undone.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text('Donor: ${donor.fullName}'),
              Text('Blood Group: ${donor.bloodGroup}'),
              Text(
                'UID: ${donor.userId}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'The following related data will be permanently removed from Firestore:\n'
                '• Donor profile & user profile\n'
                '• Profile photos & device tokens\n'
                '• Blood requests & related donations\n'
                '• Dependent notifications and alerts\n\n'
                'Do you confirm permanent deletion?',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Permanently Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      final adminUser = AuthService.currentFirebaseUser;
      final result = await AdminService.cascadeDeleteUser(
        donor.userId,
        adminId: adminUser?.uid ?? 'system_admin',
        adminName: adminUser?.displayName ?? 'System Admin',
      );

      if (!mounted) return;

      if (result.success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Firestore Application Data Deleted',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Successfully removed all ${result.totalDeletedDocs} associated Firestore records for ${donor.fullName}.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFFB45309),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Firebase Auth Manual Cleanup',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Because this project operates under the strict ₹0 Firebase plan without paid server-side functions, the client SDK cannot delete another user\'s Firebase Authentication account.\n\n'
                          'To delete the remaining Authentication identity:\n'
                          '1. Open Firebase Console -> Authentication -> Users\n'
                          '2. Search for UID: ${donor.userId}\n'
                          '3. Click More (...) and select "Delete account".',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78350F),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deletion failed at stage: ${result.failedStage} (${result.error}). Safe to retry.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _editDonor(DonorModel donor) async {
    final nameController = TextEditingController(text: donor.fullName);
    final locationController = TextEditingController(text: donor.address);
    final phoneController = TextEditingController(text: donor.phoneNumber);
    String selectedBloodGroup = donor.bloodGroup;
    bool isAvailable = donor.isAvailable;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Donor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      maxLength: 30,
                      inputFormatters: [LengthLimitingTextInputFormatter(30)],
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Address / Location',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          AdminData.bloodGroups.contains(selectedBloodGroup)
                          ? selectedBloodGroup
                          : 'O+',
                      decoration: const InputDecoration(
                        labelText: 'Blood type',
                        border: OutlineInputBorder(),
                      ),
                      items: AdminData.bloodGroups
                          .map(
                            (bloodGroup) => DropdownMenuItem<String>(
                              value: bloodGroup,
                              child: Text(bloodGroup),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedBloodGroup = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Available for Donation'),
                      value: isAvailable,
                      onChanged: (val) {
                        setDialogState(() {
                          isAvailable = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final nameErr = AppValidators.validateName(nameController.text);
      if (nameErr != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(nameErr)));
        return;
      }
      final phoneErr = AppValidators.validatePhone(phoneController.text);
      if (phoneErr != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(phoneErr)));
        return;
      }
      final addressErr = AppValidators.validateAddress(locationController.text);
      if (addressErr != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(addressErr)));
        return;
      }

      final adminUser = AuthService.currentFirebaseUser;
      final success = await DonorService.updateDonorProfile(
        donor.userId,
        fullName: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        address: locationController.text.trim(),
        bloodGroup: selectedBloodGroup,
        isAvailable: isAvailable,
        isAdmin: true, // Authorized administrator operation
      );

      if (success) {
        await AdminService.logAction(
          adminId: adminUser?.uid ?? 'system_admin',
          adminName: adminUser?.displayName ?? 'System Admin',
          action: 'donor_profile_updated',
          targetCollection: 'donor_profiles',
          targetId: donor.userId,
          title: 'Donor Blood Group & Profile Updated',
          description:
              'Admin updated donor profile for ${nameController.text.trim()} (Blood Group: $selectedBloodGroup, Available: $isAvailable).',
          details: {
            'donorId': donor.userId,
            'previousBloodGroup': donor.bloodGroup,
            'newBloodGroup': selectedBloodGroup,
            'isAvailable': isAvailable,
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Donor profile updated' : 'Failed to update donor',
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }

    nameController.dispose();
    locationController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AdminBottomBar(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminTopBar(title: 'Manage Donors'),
              const SizedBox(height: 8),

              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration:
                    adminInputDecoration(
                      hint: 'Search donors by name, location, blood type...',
                      prefixIcon: const Icon(Icons.search, color: kHintGrey),
                    ).copyWith(
                      hintStyle: const TextStyle(
                        color: kHintGrey,
                        fontSize: 14,
                      ),
                    ),
              ),

              const SizedBox(height: 14),

              // Filter blood groups horizontally
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipButton(
                      label: 'All Donors',
                      selected: _selectedFilter == 'All Donors',
                      onTap: () {
                        setState(() {
                          _selectedFilter = 'All Donors';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...AdminData.bloodGroups.map(
                      (bloodGroup) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChipButton(
                          label: bloodGroup,
                          selected: _selectedFilter == bloodGroup,
                          onTap: () {
                            setState(() {
                              _selectedFilter = bloodGroup;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stream of donors from Firestore
              StreamBuilder<List<DonorModel>>(
                stream: DonorService.streamDonors(
                  bloodGroup: _selectedFilter == 'All Donors'
                      ? null
                      : _selectedFilter,
                ),
                builder: (context, snapshot) {
                  final allDonors = snapshot.data ?? [];
                  final query = _searchController.text.trim().toLowerCase();

                  final filteredDonors = allDonors.where((donor) {
                    final matchesQuery =
                        query.isEmpty ||
                        donor.fullName.toLowerCase().contains(query) ||
                        donor.address.toLowerCase().contains(query) ||
                        donor.bloodGroup.toLowerCase().contains(query);
                    return matchesQuery;
                  }).toList();

                  final activeCount = allDonors
                      .where((d) => d.isAvailable)
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genuine Real-time Stats
                      Row(
                        children: [
                          Expanded(
                            child: _DonorStatCard(
                              label: 'TOTAL DONORS',
                              value: '${allDonors.length}',
                              valueColor: kAdminBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DonorStatCard(
                              label: 'AVAILABLE TODAY',
                              value: '$activeCount',
                              valueColor: kAdminOrange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Donor List',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (filteredDonors.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_off_outlined,
                                  size: 48,
                                  color: kHintGrey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No donors found.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: kTextMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filteredDonors.map(
                          (donor) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DonorCard(
                              donor: donor,
                              onEdit: () => _editDonor(donor),
                              onDelete: () => _confirmDelete(donor),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFFCBD5E1) : kBorderGrey,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? kTextDark : kTextMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DonorStatCard extends StatelessWidget {
  const _DonorStatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: adminCardDecoration(),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              color: kHintGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  const _DonorCard({
    required this.donor,
    required this.onEdit,
    required this.onDelete,
  });

  final DonorModel donor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: adminCardDecoration(),
      child: Row(
        children: [
          RequesterAvatar(
            userId: donor.userId,
            photoUrl: donor.profileImageUrl,
            name: donor.fullName,
            radius: 26,
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
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${donor.address}, ${donor.city}',
                  style: const TextStyle(color: kTextMuted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      donor.bloodGroup,
                      style: const TextStyle(
                        color: kAdminBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: donor.isAvailable
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        donor.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: donor.isAvailable
                              ? const Color(0xFF15803D)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: kAdminBlue),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: kAdminBlue),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
