import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Bokul/donation_service.dart';
import '../Bokul/donor_model.dart';
import '../Bokul/donor_service.dart';
import '../Bokul/user_nav.dart';
import '../Bokul/user_service.dart';
import '../Manob/auth_service.dart';
import '../Manob/donation_model.dart';
import '../Manob/firebase_service.dart';
import '../Manob/user_model.dart';
import 'admin_data.dart';
import 'admin_nav.dart';
import 'admin_service.dart';
import 'admin_theme.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  int _selectedTab = 0; // 0: Users, 1: Pending Verifications
  bool _isProcessing = false;

  // ---------------------------------------------------------
  // VERIFY / REJECT DONATIONS (Workflow: Step 5)
  // ---------------------------------------------------------

  Future<void> _verifyDonation(DonationModel donation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Blood Donation'),
        content: Text(
          'Confirm that ${donation.donorName} donated ${donation.unitsDonated} unit(s) of ${donation.bloodGroup} for patient "${donation.patientName}"?\n\nThis will permanently increment the donor\'s verified totals and set their recovery cooldown.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify & Update Totals'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    final admin = FirebaseService.auth.currentUser;
    final res = await DonationService.adminVerifyDonation(
      donationId: donation.id,
      adminId: admin?.uid ?? 'admin',
      adminName: admin?.displayName ?? 'Administrator',
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['success'] == true
              ? 'Donation verified successfully! Donor statistics updated.'
              : 'Failed to verify donation: ${res['error'] ?? 'Unknown error'}',
        ),
        backgroundColor: res['success'] == true
            ? Colors.green
            : Colors.redAccent,
      ),
    );
  }

  Future<void> _rejectDonation(DonationModel donation) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Donation Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejecting this donation will flag it as rejected without changing ${donation.donorName}\'s donation statistics.',
              style: const TextStyle(fontSize: 13, color: kTextMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g., Incomplete verification, donor cancelled',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Reject Donation'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    final admin = FirebaseService.auth.currentUser;
    final res = await DonationService.adminRejectDonation(
      donationId: donation.id,
      adminId: admin?.uid ?? 'admin',
      adminName: admin?.displayName ?? 'Administrator',
      reason: reasonController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['success'] == true
              ? 'Donation rejected. Participants have been notified.'
              : 'Failed: ${res['error'] ?? 'Unknown error'}',
        ),
        backgroundColor: res['success'] == true
            ? Colors.orange
            : Colors.redAccent,
      ),
    );
    reasonController.dispose();
  }

  void _showDonationDetails(DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                donation.bloodGroup,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Donation Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Donation ID', donation.id),
              _detailRow('Patient Name', donation.patientName ?? 'N/A'),
              _detailRow('Hospital / Location', donation.hospitalLocation),
              _detailRow('Confirmed Units', '${donation.unitsDonated} Unit(s)'),
              const Divider(height: 18),
              _detailRow('Donor Name', donation.donorName),
              _detailRow('Donor ID', donation.donorId),
              const Divider(height: 18),
              _detailRow('Requester Name', donation.requesterName ?? 'N/A'),
              _detailRow('Requester ID', donation.requesterId ?? 'N/A'),
              if (donation.bloodRequestId != null)
                _detailRow('Request Reference', donation.bloodRequestId!),
              const Divider(height: 18),
              _detailRow('Status', donation.status.toUpperCase()),
              if (donation.rejectionReason != null)
                _detailRow('Rejection Reason', donation.rejectionReason!),
              _detailRow(
                'Confirmed At',
                '${donation.createdAt.day}/${donation.createdAt.month}/${donation.createdAt.year} ${donation.createdAt.hour}:${donation.createdAt.minute.toString().padLeft(2, '0')}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (donation.isPendingVerification) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _rejectDonation(donation);
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _verifyDonation(donation);
              },
              child: const Text('Verify'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kTextMuted,
            ),
          ),
          const SizedBox(height: 1),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextDark,
            ),
          ),
        ],
      ),
    );
  }
  // ---------------------------------------------------------
  // EDIT USER & RECORD/VERIFY DONATION (Workflow B)
  // ---------------------------------------------------------

  Future<void> _editUser(UserModel user, DonorModel? donor) async {
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber);

    final lastDateFormatted = donor?.lastDonationAt != null
        ? '${donor!.lastDonationAt!.day.toString().padLeft(2, '0')}/'
              '${donor.lastDonationAt!.month.toString().padLeft(2, '0')}/'
              '${donor.lastDonationAt!.year}'
        : 'None recorded';

    String selectedBloodGroup = donor?.bloodGroup ?? 'O+';
    String selectedRole = user.role;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit User Account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      maxLength: 30,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                        LengthLimitingTextInputFormatter(30),
                      ],
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true, // Email cannot be arbitrarily changed
                      decoration: const InputDecoration(
                        labelText: 'Email Address (Read-only)',
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    DropdownButtonFormField<String>(
                      initialValue:
                          AdminData.bloodGroups.contains(selectedBloodGroup)
                          ? selectedBloodGroup
                          : 'O+',
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
                        if (value != null) {
                          setDialogState(() {
                            selectedBloodGroup = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'User Role'),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // Read-only Donation Statistics Section (Requirement 3: Admins cannot manually edit donation totals)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: kAdminBlue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'DONATION TOTALS (READ-ONLY)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: kAdminBlue,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Donations: ${donor?.totalDonationCount ?? 0}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: kTextDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Units Donated: ${donor?.totalUnitsDonated ?? 0} Unit(s)',
                            style: const TextStyle(
                              fontSize: 13,
                              color: kTextDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Last Donation: $lastDateFormatted',
                            style: const TextStyle(
                              fontSize: 12,
                              color: kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Donation totals are derived strictly from confirmed completed donations and cannot be altered manually.',
                            style: TextStyle(
                              fontSize: 10,
                              color: kTextMuted,
                              fontStyle: FontStyle.italic,
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
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }
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

    if (saved == true && mounted) {
      // 1. Update user profile
      await UserService.updateUserProfile(
        user.uid,
        fullName: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
      );

      // 2. Update role if changed
      if (selectedRole != user.role) {
        await UserService.adminUpdateUser(user.uid, role: selectedRole);
      }

      // 3. Update blood group on donor profile with explicit admin authorization
      await DonorService.updateDonorProfile(
        user.uid,
        fullName: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        bloodGroup: selectedBloodGroup,
        isAdmin: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User profile details updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  // ---------------------------------------------------------
  // DELETE USER & CASCADE DATA REMOVAL
  // ---------------------------------------------------------

  Future<void> _confirmDelete(UserModel user) async {
    final adminUser = AuthService.currentFirebaseUser;
    if (user.uid == adminUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own administrator account.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (user.role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Administrators cannot be deleted through ordinary user management.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
              Text('User: ${user.fullName}'),
              Text('Email: ${user.email}'),
              Text(
                'UID: ${user.uid}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'The following related data will be permanently removed from Firestore:\n'
                '• User profile & donor profile\n'
                '• Profile photos & device tokens\n'
                '• Blood requests created by this user\n'
                '• Associated donation records\n'
                '• User notifications and alerts\n\n'
                'Do you confirm permanent deletion?',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Permanently Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      final adminUser = AuthService.currentFirebaseUser;
      final result = await AdminService.cascadeDeleteUser(
        user.uid,
        adminId: adminUser?.uid ?? 'system_admin',
        adminName: adminUser?.displayName ?? 'System Admin',
      );

      if (!mounted) return;

      if (result.success) {
        // Show detailed result with manual Firebase Console Auth instructions
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
                    'Successfully removed all ${result.totalDeletedDocs} associated Firestore records for ${user.fullName}.',
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
                          'To permanently delete the remaining login identity:\n'
                          '1. Open Firebase Console -> Authentication -> Users\n'
                          '2. Search for: ${user.email} (${user.uid})\n'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AdminBottomBar(currentIndex: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminTopBar(title: 'Manage Users & Donations'),
              const SizedBox(height: 10),

              // Tab Selection: Users vs Pending Verifications
              StreamBuilder<List<DonationModel>>(
                stream: DonationService.streamPendingDonations(),
                builder: (context, pendingSnap) {
                  final pendingCount = (pendingSnap.data ?? []).length;

                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? kAdminBlue
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Registered Users',
                                style: TextStyle(
                                  color: _selectedTab == 0
                                      ? Colors.white
                                      : kTextMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? kAdminBlue
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Verifications',
                                  style: TextStyle(
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : kTextMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (pendingCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$pendingCount',
                                      style: TextStyle(
                                        color: _selectedTab == 1
                                            ? kAdminBlue
                                            : Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              if (_selectedTab == 0) ...[
                // Stream of users from Firestore
                StreamBuilder<List<UserModel>>(
                  stream: UserService.streamAllUsers(),
                  builder: (context, userSnapshot) {
                    final users = userSnapshot.data ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Header
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
                                      style: TextStyle(color: kTextMuted),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${users.length}',
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
                                child: Column(
                                  children: [
                                    const Text(
                                      'Admins',
                                      style: TextStyle(color: kTextMuted),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${users.where((u) => u.isAdmin).length}',
                                      style: const TextStyle(
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

                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 36),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (users.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 48,
                                    color: kHintGrey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No users found in database.',
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
                          ...users.map(
                            (user) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _UserTile(
                                user: user,
                                onEdit: (donor) => _editUser(user, donor),
                                onDelete: () => _confirmDelete(user),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ] else ...[
                // Pending Donations tab
                StreamBuilder<List<DonationModel>>(
                  stream: DonationService.streamPendingDonations(),
                  builder: (context, pendingSnap) {
                    if (pendingSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final pendingList = pendingSnap.data ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pending Donation Verifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pendingList.length} Pending',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Review requester-confirmed donations. Verifying will increment donor stats and activate recovery cooldown. Units cannot be altered manually.',
                          style: TextStyle(fontSize: 12, color: kTextMuted),
                        ),
                        const SizedBox(height: 14),

                        if (pendingList.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            decoration: adminCardDecoration(),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  size: 48,
                                  color: Color(0xFF16A34A),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'All Caught Up!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: kTextDark,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'No blood donations pending administrative verification.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...pendingList.map(
                            (donation) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PendingDonationTile(
                                donation: donation,
                                isProcessing: _isProcessing,
                                onVerify: () => _verifyDonation(donation),
                                onReject: () => _rejectDonation(donation),
                                onViewDetails: () =>
                                    _showDonationDetails(donation),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingDonationTile extends StatelessWidget {
  final DonationModel donation;
  final bool isProcessing;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const _PendingDonationTile({
    required this.donation,
    required this.isProcessing,
    required this.onVerify,
    required this.onReject,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  donation.bloodGroup,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient: ${donation.patientName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hospital: ${donation.hospitalLocation}',
                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donor',
                      style: TextStyle(fontSize: 11, color: kTextMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      donation.donorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requester',
                      style: TextStyle(fontSize: 11, color: kTextMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      donation.requesterName ?? 'Requester',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirmed Units',
                      style: TextStyle(fontSize: 11, color: kTextMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${donation.unitsDonated} Unit(s)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kAdminBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Details'),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                ),
                onPressed: isProcessing ? null : onReject,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
                onPressed: isProcessing ? null : onVerify,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Verify'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final Function(DonorModel?) onEdit;
  final VoidCallback onDelete;

  const _UserTile({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DonorModel?>(
      stream: DonorService.streamDonorProfile(user.uid),
      builder: (context, donorSnapshot) {
        final donor = donorSnapshot.data;
        final bloodGroup = donor?.bloodGroup ?? 'O+';
        final totalDonations = donor?.totalDonationCount ?? 0;
        final totalUnits = donor?.totalUnitsDonated ?? 0;
        final lastDonation = donor?.lastDonationAt != null
            ? '${donor!.lastDonationAt!.day}/${donor.lastDonationAt!.month}/${donor.lastDonationAt!.year}'
            : 'None';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: adminCardDecoration(),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RequesterAvatar(
                    userId: user.uid,
                    photoUrl: user.profileImageUrl ?? donor?.profileImageUrl,
                    name: user.fullName,
                    radius: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: kTextDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                bloodGroup,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: user.isAdmin
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  color: user.isAdmin
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF6B7280),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onEdit(donor),
                    icon: const Icon(Icons.edit_outlined, color: kAdminBlue),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: kAdminBlue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DonationInfo(
                      icon: Icons.bloodtype_outlined,
                      title: 'Last Donation',
                      value: lastDonation,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DonationInfo(
                      icon: Icons.repeat,
                      title: 'Total Donations',
                      value: '$totalDonations Times',
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
                      title: 'Verified Units',
                      value: '$totalUnits Units',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DonationInfo(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: user.phoneNumber.isNotEmpty
                          ? user.phoneNumber
                          : 'Not set',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

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
          Icon(icon, size: 18, color: kAdminBlue),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
