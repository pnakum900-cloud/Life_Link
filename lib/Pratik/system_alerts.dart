import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Bokul/blood_request_service.dart';
import '../Bokul/donation_service.dart';
import '../Bokul/user_nav.dart';
import '../Manob/auth_service.dart';
import '../Manob/blood_request_model.dart';
import '../Manob/donation_model.dart';
import 'admin_log_model.dart';
import 'admin_nav.dart';
import 'admin_service.dart';
import 'admin_theme.dart';

class SystemAlerts extends StatefulWidget {
  const SystemAlerts({super.key});

  @override
  State<SystemAlerts> createState() => _SystemAlertsState();
}

class _SystemAlertsState extends State<SystemAlerts> {
  String _selectedTab = 'active'; // 'active' or 'hidden'

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
    }
  }

  Future<void> _markAllRead() async {
    final success = await AdminService.markAllLogsAsRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'All alerts marked as read'
              : 'Failed to update alert statuses',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _handleToggleHide(String logId, bool currentlyHidden) async {
    final adminUser = AuthService.currentFirebaseUser;
    final adminId = adminUser?.uid ?? 'admin_system';

    if (currentlyHidden) {
      final success = await AdminService.unhideItem(
        adminId: adminId,
        targetType: 'alert',
        targetId: logId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Alert restored to active feed.'
                : 'Failed to restore alert.',
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    } else {
      final success = await AdminService.hideItem(
        adminId: adminId,
        targetType: 'alert',
        targetId: logId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Alert hidden (view in Hidden tab).'
                : 'Failed to hide alert.',
          ),
          backgroundColor: success ? Colors.grey.shade800 : Colors.redAccent,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // RECORD-AWARE VIEW DETAILS IMPLEMENTATION
  // ---------------------------------------------------------------------------

  Future<void> _openAlertDetails(AdminLogModel log) async {
    // Mark as read upon viewing
    await AdminService.markLogAsRead(log.logId);

    // Explicit routing: based on canonical targetCollection
    if (log.targetCollection == 'donations') {
      await _showDonationRecordDetails(log);
    } else if (log.targetCollection == 'blood_requests') {
      await _showBloodRequestRecordDetails(log);
    } else {
      _showGenericLogDetails(log);
    }
  }

  Future<void> _showDonationRecordDetails(AdminLogModel log) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    DocumentSnapshot? doc;
    try {
      doc = await FirebaseFirestore.instance
          .collection('donations')
          .doc(log.targetId)
          .get();

      if (!doc.exists) {
        // Fallback: search by bloodRequestId if targetId is a request ID
        final snap = await FirebaseFirestore.instance
            .collection('donations')
            .where('bloodRequestId', isEqualTo: log.targetId)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          doc = snap.docs.first;
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      }
    }

    if (doc == null || !doc.exists) {
      // Safe fallback displaying audit details
      _showGenericLogDetails(log);
      return;
    }

    final donation = DonationModel.fromFirestore(doc);
    final adminUser = AuthService.currentFirebaseUser;
    final adminId = adminUser?.uid ?? 'admin_system';
    final adminName = adminUser?.displayName ?? 'System Admin';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isPending = donation.isPendingVerification;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.volunteer_activism, color: kAdminBlue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Donation Record',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: donation.isVerified
                          ? const Color(0xFFDCFCE7)
                          : (donation.isRejected
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      donation.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: donation.isVerified
                            ? const Color(0xFF15803D)
                            : (donation.isRejected
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFFB45309)),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _infoRow('Donation ID', donation.donationId),
                    if (donation.patientName != null)
                      _infoRow('Patient Name', donation.patientName!),
                    _infoRow('Blood Group', donation.bloodGroup),
                    _infoRow(
                      'Confirmed Units',
                      '${donation.unitsDonated} Unit(s)',
                    ),
                    _infoRow('Hospital', donation.hospitalName),
                    if (donation.hospitalAddress != null)
                      _infoRow('Hospital Address', donation.hospitalAddress!),
                    const Divider(height: 16, color: Color(0xFFE5E7EB)),
                    _infoRow(
                      'Donor Name',
                      donation.donorName.isNotEmpty
                          ? donation.donorName
                          : 'Donor',
                    ),
                    _infoRow(
                      'Requester Name',
                      donation.requesterName ?? 'Requester',
                    ),
                    if (donation.donationDate != null)
                      _infoRow(
                        'Donation Date',
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(donation.donationDate!),
                      ),
                    if (donation.verifiedAt != null)
                      _infoRow(
                        'Verified At',
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(donation.verifiedAt!),
                      ),
                    if (donation.rejectionReason != null)
                      _infoRow('Rejection Reason', donation.rejectionReason!),
                    const SizedBox(height: 8),
                    if (isPending) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.pending_actions,
                              size: 16,
                              color: Color(0xFFB45309),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Awaiting administrative verification. Units cannot be altered.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Close'),
                ),
                if (isPending) ...[
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _promptRejectDonation(
                        context,
                        donation,
                        adminId,
                        adminName,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                    ),
                    child: const Text('Reject Record'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _verifyDonationAction(
                        context,
                        donation,
                        adminId,
                        adminName,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Verify Donation'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _verifyDonationAction(
    BuildContext context,
    DonationModel donation,
    String adminId,
    String adminName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Blood Donation'),
        content: Text(
          'Verify donation of ${donation.unitsDonated} unit(s) donated by ${donation.donorName} for ${donation.patientName}? This will update the donor\'s verified totals and set recovery cooldown.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Verification'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final messenger = ScaffoldMessenger.of(this.context);
    final res = await DonationService.adminVerifyDonation(
      donationId: donation.donationId,
      adminId: adminId,
      adminName: adminName,
    );

    if (!mounted) return;
    final success = res['success'] == true;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Donation verified successfully! Donor statistics updated.'
              : 'Failed to verify donation: ${res['error'] ?? 'Unknown error'}',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _promptRejectDonation(
    BuildContext context,
    DonationModel donation,
    String adminId,
    String adminName,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Donation Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject donation of ${donation.unitsDonated} unit(s) for ${donation.patientName}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject Donation'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final messenger = ScaffoldMessenger.of(this.context);
    final res = await DonationService.adminRejectDonation(
      donationId: donation.donationId,
      adminId: adminId,
      reason: reasonController.text.trim().isNotEmpty
          ? reasonController.text.trim()
          : null,
      adminName: adminName,
    );

    if (!mounted) return;
    final success = res['success'] == true;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Donation record rejected.'
              : 'Failed to reject donation: ${res['error'] ?? 'Unknown error'}',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _showBloodRequestRecordDetails(AdminLogModel log) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    DocumentSnapshot? doc;
    try {
      doc = await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(log.targetId)
          .get();
    } catch (_) {
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      }
    }

    if (!mounted) return;

    if (doc == null || !doc.exists) {
      _showGenericLogDetails(log);
      return;
    }

    final req = BloodRequestModel.fromFirestore(doc);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.bloodtype, color: kAdminBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Blood Request Details',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoRow('Patient Name', req.patientName),
                _infoRow('Blood Group', req.bloodGroup),
                _infoRow('Units Needed', '${req.units} Unit(s)'),
                _infoRow('Hospital', req.hospitalName),
                _infoRow('City', req.city),
                _infoRow('Contact Phone', req.contactNumber),
                _infoRow('Urgency', req.urgency.toUpperCase()),
                _infoRow('Status', req.status.toUpperCase()),
                _infoRow('Requested By', req.displayRequesterName),
                if (log.action == 'donation_not_completed') ...[
                  const Divider(height: 16, color: Color(0xFFE5E7EB)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UNSUCCESSFUL DONATION REPORT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _infoRow(
                          'Assigned Donor',
                          log.details?['donorName']?.toString() ??
                              req.lastUnsuccessfulAttempt?['donorName']
                                  ?.toString() ??
                              'N/A',
                        ),
                        _infoRow('Reported By', log.displayActorName),
                        _infoRow(
                          'Reason',
                          log.details?['reason']?.toString() ??
                              req.unsuccessfulAttemptReason ??
                              'Not specified',
                        ),
                        _infoRow(
                          'Current Request State',
                          '${req.status.toUpperCase()} (${req.donationStatus ?? "waiting_donor"})',
                        ),
                      ],
                    ),
                  ),
                ] else if (log.action == 'donor_released') ...[
                  const Divider(height: 16, color: Color(0xFFE5E7EB)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DONOR RELEASE AUDIT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _infoRow(
                          'Released Donor',
                          log.details?['donorName']?.toString() ?? 'N/A',
                        ),
                        _infoRow('Released By', log.displayActorName),
                        _infoRow(
                          'Current Request State',
                          '${req.status.toUpperCase()} (${req.donationStatus ?? "waiting_donor"})',
                        ),
                      ],
                    ),
                  ),
                ],
                if (req.hasConfirmedDonor) ...[
                  const Divider(height: 16, color: Color(0xFFE5E7EB)),
                  const Text(
                    'ASSIGNED DONOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _infoRow('Donor Name', req.displayDonorName),
                  _infoRow('Donor Blood Group', req.donorBloodGroup ?? 'N/A'),
                  _infoRow('Donor Phone', req.donorPhone ?? 'Not provided'),
                  _infoRow(
                    'Donation Status',
                    req.donationStatus ?? 'donor_accepted',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                AdminNav.toTab(context, 2); // Go to Blood Requests Tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAdminBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Requests Tab'),
            ),
          ],
        );
      },
    );
  }

  void _showGenericLogDetails(AdminLogModel log) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          log.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                log.displayDescription,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              _infoRow('Actor', log.displayActorName),
              _infoRow('Action', log.action),
              _infoRow(
                'Timestamp',
                DateFormat('MMM dd, yyyy - hh:mm a').format(log.createdAt),
              ),
              if (log.details != null && log.details!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                ...log.details!.entries.map(
                  (e) => Text(
                    '• ${e.key}: ${e.value}',
                    style: const TextStyle(fontSize: 12, color: kTextMuted),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kHintGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminUser = AuthService.currentFirebaseUser;
    final adminId = adminUser?.uid ?? 'admin_system';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AdminBottomBar(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminTopBar(title: 'System Alerts & Audit'),
              const SizedBox(height: 8),

              // Header Statistics (Streamed)
              StreamBuilder<List<BloodRequestModel>>(
                stream: BloodRequestService.streamAllRequests(),
                builder: (context, reqSnapshot) {
                  final requests = reqSnapshot.data ?? [];
                  final criticalCount = requests
                      .where(
                        (r) =>
                            r.isPending &&
                            r.urgency.toLowerCase() == 'critical',
                      )
                      .length;
                  final approvedToday = requests
                      .where((r) => r.isApproved)
                      .length;

                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kCriticalBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Critical Requests',
                                style: TextStyle(
                                  color: kCriticalText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${criticalCount.toString().padLeft(2, '0')} ',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: kCriticalText,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Pending',
                                      style: TextStyle(
                                        color: kCriticalText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: adminCardDecoration(),
                          child: Column(
                            children: [
                              const Text(
                                'Approved Requests',
                                style: TextStyle(
                                  color: kTextMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${approvedToday.toString().padLeft(2, '0')} ',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: kAdminBlue,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Total',
                                      style: TextStyle(
                                        color: kTextMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Streams hidden alert IDs
              StreamBuilder<Set<String>>(
                stream: AdminService.streamHiddenItemIds(
                  adminId: adminId,
                  targetType: 'alert',
                ),
                builder: (context, hiddenSnap) {
                  final hiddenIds = hiddenSnap.data ?? <String>{};

                  return StreamBuilder<List<AdminLogModel>>(
                    stream: AdminService.streamAdminLogs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final allLogs = snapshot.data ?? [];
                      final unreadCount = allLogs
                          .where((l) => !l.isRead)
                          .length;

                      final visibleLogs = allLogs.where((l) {
                        final isHidden = hiddenIds.contains(l.logId);
                        if (_selectedTab == 'hidden') {
                          return isHidden;
                        }
                        return !isHidden;
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tab selection: Active Alerts vs Hidden Alerts (wrapped in SingleChildScrollView to prevent RenderFlex overflow on narrow screens)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    'Active Alerts (${allLogs.length - hiddenIds.length})',
                                  ),
                                  selected: _selectedTab == 'active',
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedTab = 'active';
                                    });
                                  },
                                  selectedColor: const Color(0xFFDBEAFE),
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedTab == 'active'
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: _selectedTab == 'active'
                                        ? kAdminBlue
                                        : kTextMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text('Hidden (${hiddenIds.length})'),
                                  selected: _selectedTab == 'hidden',
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedTab = 'hidden';
                                    });
                                  },
                                  selectedColor: const Color(0xFFFEE2E2),
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedTab == 'hidden'
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: _selectedTab == 'hidden'
                                        ? const Color(0xFFB91C1C)
                                        : kTextMuted,
                                  ),
                                ),
                                if (unreadCount > 0 &&
                                    _selectedTab == 'active') ...[
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    onPressed: _markAllRead,
                                    icon: const Icon(Icons.done_all, size: 16),
                                    label: const Text('Mark all read'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: kAdminBlue,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (visibleLogs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      _selectedTab == 'hidden'
                                          ? Icons.visibility_off_outlined
                                          : Icons.notifications_none,
                                      size: 48,
                                      color: kHintGrey,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedTab == 'hidden'
                                          ? 'No hidden alerts.'
                                          : 'No audit records or alerts right now.',
                                      style: const TextStyle(
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
                            ...visibleLogs.map((log) {
                              final isHidden = hiddenIds.contains(log.logId);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _LogCard(
                                  log: log,
                                  isHidden: isHidden,
                                  formattedTime: _formatTime(log.createdAt),
                                  onView: () => _openAlertDetails(log),
                                  onMarkRead: () =>
                                      AdminService.markLogAsRead(log.logId),
                                  onToggleHide: () =>
                                      _handleToggleHide(log.logId, isHidden),
                                ),
                              );
                            }),
                        ],
                      );
                    },
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

class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.log,
    required this.isHidden,
    required this.formattedTime,
    required this.onView,
    required this.onMarkRead,
    required this.onToggleHide,
  });

  final AdminLogModel log;
  final bool isHidden;
  final String formattedTime;
  final VoidCallback onView;
  final VoidCallback onMarkRead;
  final VoidCallback onToggleHide;

  Color _badgeColor(String action) {
    if (action.contains('approved') ||
        action.contains('verified') ||
        action.contains('completed')) {
      return const Color(0xFFDCFCE7);
    } else if (action.contains('rejected') ||
        action.contains('deleted') ||
        action.contains('did_not_happen') ||
        action.contains('not_completed')) {
      return const Color(0xFFFEE2E2);
    } else if (action.contains('republished') ||
        action.contains('accepted') ||
        action.contains('pending')) {
      return const Color(0xFFFEF3C7);
    }
    return const Color(0xFFEFF6FF);
  }

  Color _badgeTextColor(String action) {
    if (action.contains('approved') ||
        action.contains('verified') ||
        action.contains('completed')) {
      return const Color(0xFF15803D);
    } else if (action.contains('rejected') ||
        action.contains('deleted') ||
        action.contains('did_not_happen') ||
        action.contains('not_completed')) {
      return const Color(0xFFB91C1C);
    } else if (action.contains('republished') ||
        action.contains('accepted') ||
        action.contains('pending')) {
      return const Color(0xFFB45309);
    }
    return kAdminBlue;
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !log.isRead;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB),
          width: isUnread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor Row + Action Badges + Hide Action
          Row(
            children: [
              RequesterAvatar(
                userId: log.actorId,
                photoUrl: log.actorPhotoUrl,
                name: log.displayActorName,
                radius: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.displayActorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 11, color: kHintGrey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _badgeColor(log.action),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  log.action.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _badgeTextColor(log.action),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  isHidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: isHidden ? const Color(0xFF15803D) : kHintGrey,
                ),
                tooltip: isHidden ? 'Restore alert' : 'Hide alert',
                onPressed: onToggleHide,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title & Description
          Text(
            log.displayTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            log.displayDescription,
            style: const TextStyle(
              fontSize: 13,
              color: kTextMuted,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Action Row
          Row(
            children: [
              if (isUnread) ...[
                TextButton(
                  onPressed: onMarkRead,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: kAdminBlue,
                  ),
                  child: const Text(
                    'Mark as read',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAdminBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
