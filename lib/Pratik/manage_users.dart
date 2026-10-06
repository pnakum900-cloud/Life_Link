import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_data.dart';
import 'admin_nav.dart';
import 'admin_theme.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  List<Map<String, dynamic>> get _users => AdminData.users;

  // ---------------------------------------------------------
  // EDIT USER
  // ---------------------------------------------------------

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameController = TextEditingController(
      text: user['name']?.toString() ?? '',
    );

    final emailController = TextEditingController(
      text: user['email']?.toString() ?? '',
    );

    final roleController = TextEditingController(
      text: user['role']?.toString() ?? '',
    );

    final donationUnitsController = TextEditingController(
      text: user['donationUnits']?.toString() ?? '',
    );

    final donationDateController = TextEditingController(
      text: user['donationDate']?.toString() ?? '',
    );

    final donationHospitalController = TextEditingController(
      text: user['donationHospital']?.toString() ?? '',
    );

    final lastDonationController = TextEditingController(
      text: user['lastDonation']?.toString() ?? '',
    );

    final totalDonationsController = TextEditingController(
      text: user['totalDonations']?.toString() ?? '',
    );

    String selectedBloodGroup =
        user['bloodGroup']?.toString() ??
        _extractBloodGroup(user['role']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit User',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -------------------------------------------------
                    // NAME
                    // -------------------------------------------------

                    TextField(
                      controller: nameController,
                      maxLength: 30,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z ]'),
                        ),
                        LengthLimitingTextInputFormatter(30),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter name',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // -------------------------------------------------
                    // EMAIL
                    // -------------------------------------------------

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'example@gmail.com',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // -------------------------------------------------
                    // BLOOD GROUP
                    // -------------------------------------------------

                    DropdownButtonFormField<String>(
                      value: AdminData.bloodGroups.contains(
                        selectedBloodGroup,
                      )
                          ? selectedBloodGroup
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                      ),
                      items: AdminData.bloodGroups.map((group) {
                        return DropdownMenuItem<String>(
                          value: group,
                          child: Text(group),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedBloodGroup = value;
                          roleController.text = '$value Donor';
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    // -------------------------------------------------
                    // ROLE
                    // -------------------------------------------------

                    TextField(
                      controller: roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        hintText: 'Example: AB+ Donor',
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Donation Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // -------------------------------------------------
                    // DONATION UNITS
                    // -------------------------------------------------

                    TextField(
                      controller: donationUnitsController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Units Donated',
                        hintText: 'Example: 2.5',
                        suffixText: 'Units',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // -------------------------------------------------
                    // DONATION DATE
                    // -------------------------------------------------

                    TextField(
                      controller: donationDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Donation Date',
                        hintText: 'Select donation date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime initialDate = DateTime.now();

                        final selectedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: initialDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (selectedDate != null) {
                          final formattedDate =
                              '${selectedDate.day.toString().padLeft(2, '0')}/'
                              '${selectedDate.month.toString().padLeft(2, '0')}/'
                              '${selectedDate.year}';

                          donationDateController.text = formattedDate;
                          lastDonationController.text = formattedDate;
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // -------------------------------------------------
                    // HOSPITAL
                    // -------------------------------------------------

                    TextField(
                      controller: donationHospitalController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Hospital Name',
                        hintText: 'Example: Civil Hospital',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // -------------------------------------------------
                    // LAST DONATION
                    // -------------------------------------------------

                    TextField(
                      controller: lastDonationController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Last Donation',
                        hintText: 'Select last donation date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (selectedDate != null) {
                          final formattedDate =
                              '${selectedDate.day.toString().padLeft(2, '0')}/'
                              '${selectedDate.month.toString().padLeft(2, '0')}/'
                              '${selectedDate.year}';

                          lastDonationController.text = formattedDate;
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // -------------------------------------------------
                    // TOTAL DONATIONS
                    // -------------------------------------------------

                    TextField(
                      controller: totalDonationsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Total Donations',
                        hintText: 'Example: 3',
                        suffixText: 'Times',
                      ),
                    ),
                  ],
                ),
              ),

              // -------------------------------------------------------
              // ACTION BUTTONS
              // -------------------------------------------------------

              actions: [
                TextButton(
                  onPressed: () {
                    // Only close the dialog.
                    // User stays on Manage Users page.
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final role = roleController.text.trim();
                    final units =
                        donationUnitsController.text.trim();
                    final date =
                        donationDateController.text.trim();
                    final hospital =
                        donationHospitalController.text.trim();
                    final total =
                        totalDonationsController.text.trim();

                    // NAME VALIDATION
                    if (name.isEmpty) {
                      _showDialogMessage(
                        dialogContext,
                        'Please enter name.',
                      );
                      return;
                    }

                    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(name)) {
                      _showDialogMessage(
                        dialogContext,
                        'Name can contain only letters and spaces.',
                      );
                      return;
                    }

                    if (name.length > 30) {
                      _showDialogMessage(
                        dialogContext,
                        'Name must be 30 characters or less.',
                      );
                      return;
                    }

                    // EMAIL VALIDATION
                    if (email.isEmpty) {
                      _showDialogMessage(
                        dialogContext,
                        'Please enter email.',
                      );
                      return;
                    }

                    if (!RegExp(
                      r'^[a-zA-Z0-9._%+\-]+@gmail\.com$',
                    ).hasMatch(email)) {
                      _showDialogMessage(
                        dialogContext,
                        'Please enter a valid Gmail address.',
                      );
                      return;
                    }

                    // ROLE VALIDATION
                    if (role.isEmpty) {
                      _showDialogMessage(
                        dialogContext,
                        'Please enter role.',
                      );
                      return;
                    }

                    // BLOOD GROUP VALIDATION
                    if (!AdminData.bloodGroups.contains(
                      selectedBloodGroup,
                    )) {
                      _showDialogMessage(
                        dialogContext,
                        'Please select a valid blood group.',
                      );
                      return;
                    }

                    // UNITS VALIDATION
                    if (units.isEmpty) {
                      _showDialogMessage(
                        dialogContext,
                        'Please enter donated units.',
                      );
                      return;
                    }

                    final parsedUnits = double.tryParse(units);

                    if (parsedUnits == null || parsedUnits <= 0) {
                      _showDialogMessage(
                        dialogContext,
                        'Donated units must be greater than 0.',
                      );
                      return;
                    }

                    // DATE VALIDATION
                    if (date.isEmpty) {
                      _showDialogMessage(
                        dialogContext,
                        'Please select donation date.',
                      );
                      return;
                    }

                    // HOSPITAL VALIDATION
                    if (hospital.isEmpty) {
                      _showDialogMessage(
                        dialogContext,
                        'Please enter hospital name.',
                      );
                      return;
                    }

                    // TOTAL DONATIONS VALIDATION
                    if (total.isEmpty) {
                      _showDialogMessage(
                        dialogContext,
                        'Please enter total donations.',
                      );
                      return;
                    }

                    final parsedTotal = int.tryParse(total);

                    if (parsedTotal == null || parsedTotal <= 0) {
                      _showDialogMessage(
                        dialogContext,
                        'Total donations must be greater than 0.',
                      );
                      return;
                    }

                    // SAVE
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // ---------------------------------------------------------
    // UPDATE USER
    // ---------------------------------------------------------

    if (saved == true && mounted) {
      setState(() {
        user['name'] = nameController.text.trim();
        user['email'] = emailController.text.trim();
        user['bloodGroup'] = selectedBloodGroup;
        user['role'] = roleController.text.trim();

        user['donationUnits'] =
            double.tryParse(
              donationUnitsController.text.trim(),
            ) ??
            0;

        user['donationDate'] =
            donationDateController.text.trim();

        user['donationHospital'] =
            donationHospitalController.text.trim();

        user['lastDonation'] =
            lastDonationController.text.trim();

        user['totalDonations'] =
            '${totalDonationsController.text.trim()} Times';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User details updated successfully.'),
        ),
      );
    }

    nameController.dispose();
    emailController.dispose();
    roleController.dispose();
    donationUnitsController.dispose();
    donationDateController.dispose();
    donationHospitalController.dispose();
    lastDonationController.dispose();
    totalDonationsController.dispose();
  }

  // ---------------------------------------------------------
  // BLOOD GROUP FROM ROLE
  // ---------------------------------------------------------

  String _extractBloodGroup(String role) {
    for (final group in AdminData.bloodGroups) {
      if (role.startsWith(group)) {
        return group;
      }
    }

    return AdminData.bloodGroups.first;
  }

  // ---------------------------------------------------------
  // DIALOG MESSAGE
  // ---------------------------------------------------------

  void _showDialogMessage(
    BuildContext dialogContext,
    String message,
  ) {
    showDialog(
      context: dialogContext,
      builder: (messageContext) {
        return AlertDialog(
          title: const Text('Validation'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(messageContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------
  // DELETE USER
  // ---------------------------------------------------------

  Future<void> _confirmDelete(
    Map<String, dynamic> user,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Remove ${user['name']} from registered users?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      setState(() {
        _users.removeWhere(
          (item) => item['id'] == user['id'],
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully.'),
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: const AdminBottomBar(
        currentIndex: 4,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminTopBar(
                title: 'Manage Users',
              ),

              const SizedBox(height: 8),

              // ---------------------------------------------------
              // STATISTICS
              // ---------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Users',
                            style: TextStyle(
                              color: kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_users.length}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: kAdminBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'New This Week',
                            style: TextStyle(
                              color: kTextMuted,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '+5',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: kAdminOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Text(
                'Registered Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),

              const SizedBox(height: 12),

              if (_users.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 24,
                  ),
                  child: Center(
                    child: Text(
                      'No users found.',
                    ),
                  ),
                )
              else
                ..._users.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _UserCard(
                      user: user,
                      onEdit: () => _editUser(user),
                      onDelete: () => _confirmDelete(user),
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

// ===================================================================
// USER CARD
// ===================================================================

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString() ?? 'User';
    final email = user['email']?.toString() ?? '';
    final bloodGroup =
        user['bloodGroup']?.toString() ?? '';
    final role = user['role']?.toString() ?? '';

    final lastDonation =
        user['lastDonation']?.toString() ?? '';

    final totalDonations =
        user['totalDonations']?.toString() ?? '';

    final donationUnits =
        user['donationUnits']?.toString() ?? '';

    final donationDate =
        user['donationDate']?.toString() ?? '';

    final donationHospital =
        user['donationHospital']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: adminCardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------
              // AVATAR
              // ---------------------------------------------------

              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  name.isNotEmpty
                      ? name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: kAdminBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ---------------------------------------------------
              // USER BASIC INFORMATION
              // ---------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: kTextDark,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      email,
                      style: const TextStyle(
                        color: kTextMuted,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: [
                        if (bloodGroup.isNotEmpty)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFFEE2E2),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text(
                              bloodGroup,
                              style: const TextStyle(
                                color:
                                    Color(0xFFB91C1C),
                                fontWeight:
                                    FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: kTextMuted,
                              fontSize: 13,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------------
              // EDIT BUTTON
              // ---------------------------------------------------

              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: kAdminBlue,
                ),
              ),

              // ---------------------------------------------------
              // DELETE BUTTON
              // ---------------------------------------------------

              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: kAdminBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 12),

          // -------------------------------------------------------
          // DONATION INFORMATION
          // -------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: _DonationInfo(
                  icon: Icons.bloodtype_outlined,
                  title: 'Last Donation',
                  value: lastDonation.isEmpty
                      ? 'Not available'
                      : lastDonation,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _DonationInfo(
                  icon: Icons.repeat,
                  title: 'Total Donations',
                  value: totalDonations.isEmpty
                      ? '0 Times'
                      : totalDonations,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _DonationInfo(
                  icon: Icons.water_drop_outlined,
                  title: 'Units Donated',
                  value: donationUnits.isEmpty
                      ? '0 Units'
                      : '$donationUnits Units',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _DonationInfo(
                  icon: Icons.local_hospital_outlined,
                  title: 'Hospital',
                  value: donationHospital.isEmpty
                      ? 'Not available'
                      : donationHospital,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------------
          // DONATION DATE
          // -------------------------------------------------------

          if (donationDate.isNotEmpty)
            _DonationInfo(
              icon: Icons.calendar_month_outlined,
              title: 'Donation Date',
              value: donationDate,
            ),
        ],
      ),
    );
  }
}

// ===================================================================
// DONATION INFO WIDGET
// ===================================================================

class _DonationInfo extends StatelessWidget {
  const _DonationInfo({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: kAdminBlue,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: kTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextDark,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}