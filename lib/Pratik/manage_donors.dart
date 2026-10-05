
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_data.dart';
import 'admin_nav.dart';
import 'admin_theme.dart';

class ManageDonors extends StatefulWidget {
  const ManageDonors({super.key});

  @override
  State<ManageDonors> createState() => _ManageDonorsState();
}

class _ManageDonorsState extends State<ManageDonors> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All Donors';

  List<Map<String, dynamic>> get _donors => AdminData.donors;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredDonors {
    final query = _searchController.text.trim().toLowerCase();

    return _donors.where((donor) {
      final name = (donor['name'] as String).toLowerCase();
      final location = (donor['location'] as String).toLowerCase();
      final bloodType = (donor['bloodType'] as String).toLowerCase();

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          location.contains(query) ||
          bloodType.contains(query);

      final matchesFilter = _selectedFilter == 'All Donors' ||
          donor['bloodType'] == _selectedFilter;

      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _confirmDelete(Map<String, dynamic> donor) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete donor'),
          content: Text(
            'Remove ${donor['name']} from the donor list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _donors.removeWhere(
          (item) => item['id'] == donor['id'],
        );
      });
    }
  }

  Future<void> _editDonor(Map<String, dynamic> donor) async {
    final nameController = TextEditingController(
      text: donor['name'] as String,
    );

    final locationController = TextEditingController(
      text: donor['location'] as String,
    );

    String selectedBloodGroup =
        donor['bloodType'] as String;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit donor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      maxLength: 30,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(30),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          AdminData.bloodGroups.contains(
                        selectedBloodGroup,
                      )
                              ? selectedBloodGroup
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Blood type',
                        border: OutlineInputBorder(),
                      ),
                      items: AdminData.bloodGroups
                          .map(
                            (bloodGroup) =>
                                DropdownMenuItem<String>(
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      setState(() {
        donor['name'] = nameController.text.trim();
        donor['location'] =
            locationController.text.trim();
        donor['bloodType'] = selectedBloodGroup;
      });
    }

    nameController.dispose();
    locationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final donors = _filteredDonors;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar:
          const AdminBottomBar(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const AdminTopBar(
                title: 'Manage Donors',
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(
                  hint:
                      'Search donors by name, blood type...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: kHintGrey,
                  ),
                ).copyWith(
                  hintStyle: const TextStyle(
                    color: kHintGrey,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipButton(
                      label: 'All Donors',
                      selected:
                          _selectedFilter == 'All Donors',
                      onTap: () {
                        setState(() {
                          _selectedFilter = 'All Donors';
                        });
                      },
                    ),

                    const SizedBox(width: 8),

                    ...AdminData.bloodGroups.map(
                      (bloodGroup) => Padding(
                        padding:
                            const EdgeInsets.only(right: 8),
                        child: _FilterChipButton(
                          label: bloodGroup,
                          selected:
                              _selectedFilter ==
                                  bloodGroup,
                          onTap: () {
                            setState(() {
                              _selectedFilter =
                                  bloodGroup;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _DonorStatCard(
                      label: 'TOTAL DONORS',
                      value: '10',
                      valueColor: kAdminBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DonorStatCard(
                      label: 'ACTIVE TODAY',
                      value: '10',
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

              if (donors.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No donors found.',
                    ),
                  ),
                )
              else
                ...donors.map(
                  (donor) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: _DonorCard(
                      donor: donor,
                      onEdit: () =>
                          _editDonor(donor),
                      onDelete: () =>
                          _confirmDelete(donor),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? const Color(0xFFCBD5E1)
                : kBorderGrey,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? kTextDark : kTextMuted,
            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
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

  final Map<String, dynamic> donor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: adminCardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor:
                const Color(0xFFEFF6FF),
            child: Text(
              (donor['name'] as String).isNotEmpty
                  ? (donor['name'] as String)[0]
                  : 'D',
              style: const TextStyle(
                color: kAdminBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  donor['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  donor['location'] as String,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  donor['bloodType'] as String,
                  style: const TextStyle(
                    color: kAdminBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: kAdminBlue,
                ),
                visualDensity:
                    VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: kAdminBlue,
                ),
                visualDensity:
                    VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
