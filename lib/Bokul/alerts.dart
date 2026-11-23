import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Manob/auth_service.dart';
import '../Manob/blood_request_model.dart';
import '../Manob/notification_model.dart';
import 'blood_request_service.dart';
import 'donor_model.dart';
import 'donor_service.dart';
import 'notification_service.dart';
import 'user_nav.dart';

class Alerts extends StatefulWidget {
  const Alerts({super.key});

  @override
  State<Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<Alerts> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFECACA);
      case 'urgent':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  Color _urgencyTextColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB91C1C);
      case 'urgent':
        return const Color(0xFFB45309);
      default:
        return kUserBlue;
    }
  }

  Color _statusBadgeBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFDCFCE7);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      case 'cancelled':
        return const Color(0xFFF3F4F6);
      case 'pending':
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  Color _statusBadgeText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF15803D);
      case 'rejected':
        return const Color(0xFFB91C1C);
      case 'cancelled':
        return const Color(0xFF6B7280);
      case 'pending':
      default:
        return const Color(0xFFB45309);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
      default:
        return 'PENDING APPROVAL';
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return 'JUST NOW';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}M AGO';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}H AGO';
    } else {
      return DateFormat('dd MMM').format(dt).toUpperCase();
    }
  }

  Future<void> _handleAcceptRequest(
    BloodRequestModel req,
    DonorModel donor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.volunteer_activism, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Accept Blood Request',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to donate blood for ${req.patientName} (${req.bloodGroup}, ${req.units} Units) at ${req.hospitalName}?',
                style: const TextStyle(fontSize: 14, color: kUserDark),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  'Your name (${donor.fullName}) and phone number (${donor.phoneNumber}) will be shared with the requester to coordinate donation.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: kUserBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Acceptance'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final res = await BloodRequestService.acceptRequest(
      requestId: req.requestId,
      donorProfile: donor,
    );
    final success = res['success'] == true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Request accepted! Requester has been notified.'
              : 'Failed to accept request: ${res['error'] ?? 'Already assigned or closed.'}',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _handleConfirmCompletion(
    BloodRequestModel req,
    String requesterId,
  ) async {
    final unitsController = TextEditingController(text: req.units.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirm Donation Completed',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm that ${req.displayDonorName} completed the blood donation at ${req.hospitalName}?',
                style: const TextStyle(fontSize: 14, color: kUserDark),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: unitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Actual Units Donated',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.water_drop, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Completed'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final inputStr = unitsController.text.trim();
    final parsedUnits = int.tryParse(
      inputStr.isEmpty ? '${req.units}' : inputStr,
    );
    if (parsedUnits == null || parsedUnits <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid positive number of units donated.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (parsedUnits > 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Donation units cannot exceed permitted maximum of 10 units.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (parsedUnits > req.units) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Confirmed units ($parsedUnits) cannot exceed requested quantity (${req.units}).',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final res = await BloodRequestService.confirmDonationCompleted(
      requestId: req.requestId,
      requesterId: requesterId,
      confirmedUnits: parsedUnits,
    );
    final success = res['success'] == true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Donation completion recorded! Awaiting administrator verification.'
              : 'Failed to record donation completion${res['failedStage'] != null ? ' at stage: ${res['failedStage']}' : ''}: ${res['error'] ?? 'Unknown error.'}',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _handleReportDidNotHappen(
    BloodRequestModel req,
    String requesterId,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Donation Did Not Happen',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to report that the donation by ${req.displayDonorName} did not take place?',
                style: const TextStyle(fontSize: 14, color: kUserDark),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  hintText: 'e.g. Donor was unavailable, medical deferral',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Report Not Completed'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final reason = reasonController.text.trim();
    final res = await BloodRequestService.reportDonationDidNotHappen(
      requestId: req.requestId,
      requesterId: requesterId,
      reason: reason.isNotEmpty ? reason : null,
    );
    final success = res['success'] == true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Status updated: donation did not happen.'
              : 'Failed to update donation status${res['failedStage'] != null ? ' at stage: ${res['failedStage']}' : ''}: ${res['error'] ?? 'Unknown error.'}',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _handleReleaseDonorAssignment(
    BloodRequestModel req,
    String requesterId,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_open, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Release Donor Assignment',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Release assigned donor (${req.displayDonorName}) and reopen this blood request to other eligible donors?',
                style: const TextStyle(fontSize: 14, color: kUserDark),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Release',
                  hintText: 'e.g. Donor could not attend, unresponsive',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(
                      content: Text('Please state a reason for release.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogCtx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
              ),
              child: const Text('Release & Reopen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final reason = reasonController.text.trim();
    final res = await BloodRequestService.releaseDonorAssignment(
      requestId: req.requestId,
      actorId: requesterId,
      reason: reason,
    );
    final success = res['success'] == true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Donor assignment released. Request reopened for other donors.'
              : 'Failed to release donor${res['failedStage'] != null ? ' at stage: ${res['failedStage']}' : ''}: ${res['error'] ?? 'Unknown error.'}',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  void _openRequestDetails(
    BuildContext context,
    BloodRequestModel req,
    String currentUserId,
    DonorModel? currentUserDonor,
  ) {
    final isOwnRequest = req.requesterId == currentUserId;
    final isAssignedDonor = req.donorId == currentUserId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.bloodGroup,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Blood Request Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kUserDark,
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
                if (req.isRejected && isOwnRequest) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Color(0xFFB91C1C),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Your blood request was rejected by the admin.',
                                style: TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (req.rejectionReason != null &&
                            req.rejectionReason!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Reason: ${req.rejectionReason!.trim()}',
                            style: const TextStyle(
                              color: Color(0xFF7F1D1D),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Confirmed Donor card if exists and visible to parties
                if (req.hasConfirmedDonor &&
                    (isOwnRequest || isAssignedDonor)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONFIRMED DONOR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            RequesterAvatar(
                              userId: req.donorId,
                              photoUrl: req.donorPhotoUrl,
                              name: req.donorName,
                              radius: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.displayDonorName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kUserDark,
                                    ),
                                  ),
                                  Text(
                                    'Blood: ${req.donorBloodGroup ?? 'N/A'} • Phone: ${req.donorPhone ?? 'Not provided'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: kUserMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                _detailRow('Requested By', req.displayRequesterName),
                _detailRow('Patient Name', req.patientName),
                _detailRow('Units Needed', '${req.units} Unit(s)'),
                _detailRow('Hospital', req.hospitalName),
                _detailRow(
                  'Location / City',
                  '${req.hospitalAddress}, ${req.city}',
                ),
                _detailRow('Contact Number', req.contactNumber),
                _detailRow('Urgency Level', req.urgency),
                _detailRow('Status', _statusLabel(req.status)),
                _detailRow(
                  'Donation Status',
                  req.donationStatus?.toUpperCase().replaceAll('_', ' ') ??
                      'NONE',
                ),
                if (req.donorAcceptedAt != null)
                  _detailRow(
                    'Donor Accepted Time',
                    DateFormat(
                      'MMM dd, yyyy - hh:mm a',
                    ).format(req.donorAcceptedAt!),
                  ),
                _detailRow(
                  'Requested Time',
                  DateFormat('MMM dd, yyyy - hh:mm a').format(req.createdAt),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE',
                style: TextStyle(fontWeight: FontWeight.w700, color: kUserBlue),
              ),
            ),
            if (isOwnRequest && req.donationStatus == 'donor_accepted') ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleReleaseDonorAssignment(req, currentUserId);
                },
                child: const Text(
                  'RELEASE DONOR',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleReportDidNotHappen(req, currentUserId);
                },
                child: const Text(
                  'DID NOT HAPPEN',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleConfirmCompletion(req, currentUserId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('CONFIRM COMPLETED'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: kUserHint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isNotEmpty ? value : 'Not provided',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kUserDark,
            ),
          ),
          const Divider(height: 12, color: kUserBorder),
        ],
      ),
    );
  }

  void _openNotificationDetails(NotificationModel item) {
    NotificationService.markAsRead(item.notificationId);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            item.message,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Close',
                style: TextStyle(color: kUserBlue, fontWeight: FontWeight.w700),
              ),
            ),
            if (item.relatedRequestId != null &&
                item.relatedRequestId!.isNotEmpty)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final req = await BloodRequestService.getRequestById(
                    item.relatedRequestId!,
                  );
                  if (req != null && mounted) {
                    final currentUid =
                        AuthService.currentFirebaseUser?.uid ?? '';
                    final currentDonor = await DonorService.getDonorProfile(
                      currentUid,
                    );
                    if (mounted) {
                      _openRequestDetails(
                        context,
                        req,
                        currentUid,
                        currentDonor,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kUserBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Request'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentFirebaseUser;
    final userId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const UserBottomBar(currentIndex: 3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: LifeLinkHeader(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ALERTS',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: kUserDark,
                      ),
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: NotificationService.streamUnreadCount(userId),
                    builder: (context, snap) {
                      final count = snap.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count NEW',
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: kUserBlue,
              unselectedLabelColor: kUserMuted,
              indicatorColor: kUserBlue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'BLOOD REQUESTS'),
                Tab(text: 'NOTIFICATIONS'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBloodRequestsFeed(context, userId),
                  _buildNotificationsFeed(context, userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodRequestsFeed(BuildContext context, String userId) {
    return StreamBuilder<DonorModel?>(
      stream: DonorService.streamDonorProfile(userId),
      builder: (context, donorSnap) {
        final currentUserDonor = donorSnap.data;

        return StreamBuilder<List<BloodRequestModel>>(
          stream: BloodRequestService.streamAlertRequests(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Loading live alerts...',
                      style: TextStyle(color: kUserMuted, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: kUserHint),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load blood requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kUserDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: kUserHint),
                      ),
                    ],
                  ),
                ),
              );
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bloodtype_outlined,
                        size: 56,
                        color: kUserHint.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No blood request alerts found.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kUserDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Newly published requests from other users and your submitted requests will appear here automatically in real time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: kUserMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final req = requests[index];
                final isOwnRequest = req.requesterId == userId;
                final isAssignedDonor = req.donorId == userId;

                // Eligibility check for accepting request
                final hasDonorProfile = currentUserDonor != null;
                final isDonorAdmin = currentUserDonor?.isAdmin == true;
                final isDonorAvailable = currentUserDonor?.isAvailable == true;
                final isDonorReady = currentUserDonor?.isReady == true;
                final isDonorCooldown = currentUserDonor?.isCooldown == true;
                final isBloodMatch =
                    currentUserDonor != null &&
                    DonorModel.isBloodCompatible(
                      currentUserDonor.bloodGroup,
                      req.bloodGroup,
                    );

                final canAccept =
                    !isOwnRequest &&
                    req.isApproved &&
                    !req.hasConfirmedDonor &&
                    hasDonorProfile &&
                    !isDonorAdmin &&
                    isDonorReady &&
                    isDonorAvailable &&
                    isBloodMatch;

                String? ineligibilityReason;
                if (!isOwnRequest && req.isApproved && !req.hasConfirmedDonor) {
                  if (!hasDonorProfile) {
                    ineligibilityReason =
                        'Complete your donor profile to accept requests.';
                  } else if (isDonorAdmin) {
                    ineligibilityReason =
                        'Administrators cannot accept blood requests.';
                  } else if (isDonorCooldown) {
                    ineligibilityReason =
                        'You are currently in recovery cooldown period.';
                  } else if (!isDonorReady) {
                    ineligibilityReason =
                        'Donor eligibility status is ${currentUserDonor.eligibilityStatus}.';
                  } else if (!isDonorAvailable) {
                    ineligibilityReason =
                        'You are marked unavailable for blood donation.';
                  } else if (!isBloodMatch) {
                    ineligibilityReason =
                        'Blood group (${currentUserDonor.bloodGroup}) is not compatible with ${req.bloodGroup}.';
                  }
                }

                return InkWell(
                  onTap: () => _openRequestDetails(
                    context,
                    req,
                    userId,
                    currentUserDonor,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: req.isRejected && isOwnRequest
                            ? const Color(0xFFFCA5A5)
                            : (req.isApproved
                                  ? const Color(0xFFBFDBFE)
                                  : kUserBorder),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ).boxShadow!.first,
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Requester Header Row
                        Row(
                          children: [
                            RequesterAvatar(
                              userId: req.requesterId,
                              photoUrl: req.requesterPhotoUrl,
                              name: req.requesterName,
                              size: 42,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'BLOOD REQUEST',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: kUserHint,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Requested by: ${req.displayRequesterName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: kUserDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                req.bloodGroup,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 18, color: kUserBorder),

                        // Patient, hospital, location details
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Patient: ${req.patientName}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kUserDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${req.hospitalName} • ${req.city}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kUserMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${req.units} Unit(s)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kUserBlue,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Rejection alert message if rejected and owned by requester
                        if (req.isRejected && isOwnRequest) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      color: Color(0xFFDC2626),
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Your blood request was rejected by the admin.',
                                        style: TextStyle(
                                          color: Color(0xFFB91C1C),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (req.rejectionReason != null &&
                                    req.rejectionReason!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reason: ${req.rejectionReason!.trim()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7F1D1D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Confirmed Donor Card Section
                        if (req.hasConfirmedDonor &&
                            (isOwnRequest || isAssignedDonor)) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF16A34A),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAssignedDonor
                                          ? 'YOU HAVE ACCEPTED THIS REQUEST'
                                          : 'CONFIRMED DONOR ASSIGNED',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    RequesterAvatar(
                                      userId: req.donorId,
                                      photoUrl: req.donorPhotoUrl,
                                      name: req.donorName,
                                      radius: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            req.displayDonorName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: kUserDark,
                                            ),
                                          ),
                                          Text(
                                            'Blood: ${req.donorBloodGroup ?? 'N/A'} • Phone: ${req.donorPhone ?? 'Not provided'}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: kUserMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Actions for Requester to manage donor assignment
                        if (isOwnRequest && req.hasConfirmedDonor) ...[
                          if (req.donationStatus == 'donor_accepted') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _handleReportDidNotHappen(req, userId),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(
                                        color: Color(0xFFFCA5A5),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Did Not Happen',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _handleReleaseDonorAssignment(
                                          req,
                                          userId,
                                        ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFB45309),
                                      side: const BorderSide(
                                        color: Color(0xFFFCD34D),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Release Donor',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _handleConfirmCompletion(req, userId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Confirm Done',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ] else if (req.isPendingVerification) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_top,
                                    size: 16,
                                    color: Color(0xFFB45309),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Donation reported completed. Awaiting admin verification.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (req.isVerified) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Color(0xFF15803D),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Donation Verified by Admin (${req.confirmedUnits ?? req.units} Units)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        // Completed banner for assigned donor
                        if (isAssignedDonor && req.isDonationCompleted) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: req.isVerified
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  req.isVerified
                                      ? Icons.verified
                                      : Icons.hourglass_top,
                                  size: 16,
                                  color: req.isVerified
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    req.isVerified
                                        ? 'Donation Verified (${req.confirmedUnits ?? req.units} Units)'
                                        : 'Donation Reported Completed • Pending Admin Verification',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: req.isVerified
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Donor Accept Request Button for eligible donors
                        if (!isOwnRequest) ...[
                          if (req.isApproved && !req.hasConfirmedDonor) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: canAccept
                                    ? () => _handleAcceptRequest(
                                        req,
                                        currentUserDonor,
                                      )
                                    : null,
                                icon: const Icon(
                                  Icons.volunteer_activism,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Accept Request',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kUserBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFFE5E7EB,
                                  ),
                                  disabledForegroundColor: const Color(
                                    0xFF9CA3AF,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            if (ineligibilityReason != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                ineligibilityReason,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                          ] else if (req.hasConfirmedDonor &&
                              !isAssignedDonor) ...[
                            // Locked for other donors
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.lock_outline, size: 18),
                                label: const Text(
                                  'Request Already Assigned',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  disabledBackgroundColor: const Color(
                                    0xFFF3F4F6,
                                  ),
                                  disabledForegroundColor: const Color(
                                    0xFF6B7280,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'A donor has already accepted this request. Waiting for donation completion or requester release.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],

                        // Badges and time footer
                        Row(
                          children: [
                            // Urgency badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _urgencyColor(req.urgency),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                req.urgency.toUpperCase(),
                                style: TextStyle(
                                  color: _urgencyTextColor(req.urgency),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _statusBadgeBg(req.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _statusLabel(req.status),
                                style: TextStyle(
                                  color: _statusBadgeText(req.status),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),

                            if (req.isRepublished) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'REPUBLISHED',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (req.isReopened) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: const Text(
                                    'REOPENED',
                                    style: TextStyle(
                                      color: Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],

                            const Spacer(),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(req.effectiveFeedTime),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kUserHint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (req.isReopened)
                                  Text(
                                    'Orig: ${_formatTime(req.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: kUserMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsFeed(BuildContext context, String userId) {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService.streamUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_outlined,
                  size: 54,
                  color: kUserHint.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No notifications found.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kUserMuted,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Status updates on your requests and donations will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: kUserHint),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = notifications[index];
            final isRejection =
                item.title.toLowerCase().contains('reject') ||
                item.message.toLowerCase().contains('rejected');

            return InkWell(
              onTap: () => _openNotificationDetails(item),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.isRead ? Colors.white : const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isRejection
                        ? const Color(0xFFFCA5A5)
                        : (item.isRead
                              ? kUserBorder
                              : kUserBlue.withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isRejection
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isRejection
                            ? Icons.error_outline
                            : Icons.notifications_active_outlined,
                        size: 16,
                        color: isRejection
                            ? const Color(0xFFDC2626)
                            : kUserBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: isRejection
                                  ? const Color(0xFFB91C1C)
                                  : kUserDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: kUserMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(item.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: kUserHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
