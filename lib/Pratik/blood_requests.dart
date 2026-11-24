import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Bokul/blood_request_service.dart';
import '../Bokul/user_nav.dart';
import '../Manob/auth_service.dart';
import '../Manob/blood_request_model.dart';
import 'admin_nav.dart';
import 'admin_service.dart';
import 'admin_theme.dart';

class BloodRequests extends StatefulWidget {
  const BloodRequests({super.key});

  @override
  State<BloodRequests> createState() => _BloodRequestsState();
}

class _BloodRequestsState extends State<BloodRequests> {
  Future<void> _handleDecision(BloodRequestModel req, String decision) async {
    final adminUser = AuthService.currentFirebaseUser;
    final adminId = adminUser?.uid ?? 'admin_system';

    if (decision == 'rejected') {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Reject Blood Request',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reject request for ${req.patientName} (${req.bloodGroup}, ${req.units} Units)?',
                  style: const TextStyle(fontSize: 14, color: kTextDark),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason (Optional)',
                    hintText: 'e.g. Incomplete hospital details',
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
                child: const Text('Reject Request'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      final success = await BloodRequestService.adminRejectRequest(
        requestId: req.requestId,
        adminId: adminId,
        reason: reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Request rejected and requester notified'
                : 'Failed to reject request',
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
      return;
    }

    // Approval flow with confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Approve & Publish Blood Request',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Approve and publish blood request for ${req.patientName} (${req.bloodGroup}, ${req.units} Units)? Eligible donors will immediately see this request in their feed.',
            style: const TextStyle(fontSize: 14, color: kTextDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAdminBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve & Publish'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await BloodRequestService.adminApproveRequest(
      requestId: req.requestId,
      adminId: adminId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Request approved and published to donors'
              : 'Failed to update request status',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _handleRepublish(BloodRequestModel req) async {
    final adminUser = AuthService.currentFirebaseUser;
    final adminId = adminUser?.uid ?? 'admin_system';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Republish Blood Request',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Republish previously rejected request for ${req.patientName} (${req.bloodGroup}, ${req.units} Units)?',
                style: const TextStyle(fontSize: 14, color: kTextDark),
              ),
              const SizedBox(height: 10),
              const Text(
                'This will restore the request to published status, notify the requester, and make it visible to eligible donors. The previous rejection will remain preserved in the audit log.',
                style: TextStyle(fontSize: 12, color: kTextMuted),
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
                backgroundColor: kAdminBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Republish Request'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await BloodRequestService.adminRepublishRequest(
      requestId: req.requestId,
      adminId: adminId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Request republished successfully and visible to donors'
              : 'Failed to republish request',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Color _getStatusBackgroundColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFECACA);
      case 'urgent':
        return const Color(0xFFFEF3C7);
      case 'normal':
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color _getStatusTextColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB91C1C);
      case 'urgent':
        return const Color(0xFFB45309);
      case 'normal':
      default:
        return const Color(0xFF4B5563);
    }
  }

  String _selectedTab =
      'all'; // 'all', 'pending', 'approved', 'rejected', 'hidden'

  Future<void> _handleToggleHide(String requestId, bool currentlyHidden) async {
    final adminUser = AuthService.currentFirebaseUser;
    final adminId = adminUser?.uid ?? 'admin_system';

    if (currentlyHidden) {
      final success = await AdminService.unhideItem(
        adminId: adminId,
        targetType: 'request',
        targetId: requestId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Request restored to main list.'
                : 'Failed to restore request.',
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    } else {
      final success = await AdminService.hideItem(
        adminId: adminId,
        targetType: 'request',
        targetId: requestId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Request hidden from view (see Hidden tab).'
                : 'Failed to hide request.',
          ),
          backgroundColor: success ? Colors.grey.shade800 : Colors.redAccent,
        ),
      );
    }
  }

  void _showRequestDetails(BloodRequestModel req) {
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
              Expanded(
                child: Text(
                  'Request Details',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailItem('Patient Name', req.patientName),
                _detailItem('Blood Group', req.bloodGroup),
                _detailItem('Units Required', '${req.units} Unit(s)'),
                _detailItem('Hospital', req.hospitalName),
                _detailItem('Hospital Address', req.hospitalAddress),
                _detailItem('City', req.city),
                _detailItem('Contact Phone', req.contactNumber),
                _detailItem('Urgency', req.urgency.toUpperCase()),
                _detailItem('Approval Status', req.status.toUpperCase()),
                _detailItem('Public Visibility', req.visibility.toUpperCase()),
                _detailItem(
                  'Submitted At',
                  DateFormat('MMM dd, yyyy - hh:mm a').format(req.createdAt),
                ),
                if (req.isRepublished)
                  _detailItem(
                    'Republished At',
                    req.republishedAt != null
                        ? DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          ).format(req.republishedAt!)
                        : 'Yes',
                  ),
                if (req.rejectionReason != null)
                  _detailItem('Rejection Reason', req.rejectionReason!),
                if (req.hasConfirmedDonor) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 6),
                  const Text(
                    'ASSIGNED DONOR DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _detailItem('Donor Name', req.displayDonorName),
                  _detailItem(
                    'Donor Blood Group',
                    req.donorBloodGroup ?? 'N/A',
                  ),
                  _detailItem('Donor Phone', req.donorPhone ?? 'Not provided'),
                  _detailItem('Donor City', req.donorCity ?? 'Not provided'),
                  _detailItem(
                    'Donation Status',
                    req.donationStatus ?? 'donor_accepted',
                  ),
                  if (req.confirmedUnits != null)
                    _detailItem(
                      'Confirmed Units',
                      '${req.confirmedUnits} Unit(s)',
                    ),
                  if (req.acceptedAt != null)
                    _detailItem(
                      'Accepted Time',
                      DateFormat(
                        'MMM dd, yyyy - hh:mm a',
                      ).format(req.acceptedAt!),
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
        );
      },
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kHintGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
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

  @override
  Widget build(BuildContext context) {
    final adminUser = AuthService.currentFirebaseUser;
    final adminId = adminUser?.uid ?? 'admin_system';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AdminBottomBar(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminTopBar(title: 'Manage Blood Requests'),
              const SizedBox(height: 8),
              const Text(
                'Active Requests',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review, approve, reject, or republish regional hospital blood requirements.',
                style: TextStyle(fontSize: 14, height: 1.4, color: kTextMuted),
              ),
              const SizedBox(height: 16),

              // Filter Chips Row including Hidden Requests
              StreamBuilder<Set<String>>(
                stream: AdminService.streamHiddenItemIds(
                  adminId: adminId,
                  targetType: 'request',
                ),
                builder: (context, hiddenSnap) {
                  final hiddenIds = hiddenSnap.data ?? <String>{};

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All Visible'),
                            const SizedBox(width: 8),
                            _buildFilterChip('pending', 'Pending'),
                            const SizedBox(width: 8),
                            _buildFilterChip('approved', 'Approved'),
                            const SizedBox(width: 8),
                            _buildFilterChip('rejected', 'Rejected'),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'hidden',
                              'Hidden (${hiddenIds.length})',
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Real-time Stream of blood requests from Firestore
                      StreamBuilder<List<BloodRequestModel>>(
                        stream: BloodRequestService.streamAllRequests(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 36),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final allRequests = snapshot.data ?? [];

                          // Apply tab filter and hidden preference
                          final filteredRequests = allRequests.where((req) {
                            final isHidden = hiddenIds.contains(req.requestId);

                            if (_selectedTab == 'hidden') {
                              return isHidden;
                            }

                            // Normal views exclude hidden items
                            if (isHidden) return false;

                            if (_selectedTab == 'pending') {
                              return req.isPending;
                            } else if (_selectedTab == 'approved') {
                              return req.isApproved;
                            } else if (_selectedTab == 'rejected') {
                              return req.isRejected;
                            }
                            return true; // 'all' visible
                          }).toList();

                          if (filteredRequests.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      _selectedTab == 'hidden'
                                          ? Icons.visibility_off_outlined
                                          : Icons.inbox_outlined,
                                      size: 48,
                                      color: kHintGrey,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedTab == 'hidden'
                                          ? 'No hidden blood requests.'
                                          : 'No blood requests found for this filter.',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: kTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: filteredRequests.map((req) {
                              final isHidden = hiddenIds.contains(
                                req.requestId,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _RequestCard(
                                  request: req,
                                  isHidden: isHidden,
                                  statusBackgroundColor:
                                      _getStatusBackgroundColor(req.urgency),
                                  statusTextColor: _getStatusTextColor(
                                    req.urgency,
                                  ),
                                  onApprove: () =>
                                      _handleDecision(req, 'approved'),
                                  onReject: () =>
                                      _handleDecision(req, 'rejected'),
                                  onRepublish: () => _handleRepublish(req),
                                  onToggleHide: () => _handleToggleHide(
                                    req.requestId,
                                    isHidden,
                                  ),
                                  onTap: () => _showRequestDetails(req),
                                ),
                              );
                            }).toList(),
                          );
                        },
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

  Widget _buildFilterChip(
    String tabKey,
    String label, {
    bool isDestructive = false,
  }) {
    final isSelected = _selectedTab == tabKey;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedTab = tabKey;
        });
      },
      selectedColor: isDestructive
          ? const Color(0xFFFEE2E2)
          : const Color(0xFFDBEAFE),
      backgroundColor: const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected
            ? (isDestructive ? const Color(0xFFB91C1C) : kAdminBlue)
            : kTextMuted,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? (isDestructive
                    ? const Color(0xFFFCA5A5)
                    : kAdminBlue.withValues(alpha: 0.3))
              : Colors.transparent,
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isHidden,
    required this.statusBackgroundColor,
    required this.statusTextColor,
    required this.onApprove,
    required this.onReject,
    required this.onRepublish,
    required this.onToggleHide,
    required this.onTap,
  });

  final BloodRequestModel request;
  final bool isHidden;
  final Color statusBackgroundColor;
  final Color statusTextColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRepublish;
  final VoidCallback onToggleHide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPending = request.isPending;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: adminCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requester Header + Hide Action
            Row(
              children: [
                RequesterAvatar(
                  userId: request.requesterId,
                  photoUrl: request.requesterPhotoUrl,
                  name: request.requesterName,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blood request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      ),
                      Text(
                        'Requested by: ${request.displayRequesterName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kTextMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isHidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: isHidden ? const Color(0xFF15803D) : kHintGrey,
                  ),
                  tooltip: isHidden ? 'Restore to main list' : 'Hide from list',
                  onPressed: onToggleHide,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      request.bloodGroup,
                      style: const TextStyle(
                        color: kAdminBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${request.units} Unit(s)',
                      style: const TextStyle(color: kTextMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),

            Row(
              children: [
                // URGENCY BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    request.urgency.toUpperCase(),
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // VISIBILITY BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: request.isPublished
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.isPublished ? 'PUBLISHED' : 'PRIVATE',
                    style: TextStyle(
                      color: request.isPublished
                          ? const Color(0xFF15803D)
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),

                if (request.isRepublished) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
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
                ],
              ],
            ),

            const SizedBox(height: 12),

            Text(
              request.hospitalName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '${request.hospitalAddress}, ${request.city}',
              style: const TextStyle(color: kTextMuted, fontSize: 13),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  'Patient: ${request.patientName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Contact: ${request.contactNumber}',
                  style: const TextStyle(color: kTextMuted, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              'Submitted: ${DateFormat('MMM dd, yyyy - hh:mm a').format(request.createdAt)}',
              style: const TextStyle(color: kHintGrey, fontSize: 11),
            ),

            if (request.isRejected &&
                request.rejectionReason != null &&
                request.rejectionReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection Reason: ${request.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Confirmed Donor Section (if assigned)
            if (request.hasConfirmedDonor) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF16A34A),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'CONFIRMED DONOR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: request.isDonationCompleted
                                ? const Color(0xFFDCFCE7)
                                : (request.donationStatus == 'not_completed'
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFDBEAFE)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            request.isDonationCompleted
                                ? 'COMPLETED (${request.confirmedUnits ?? request.units}U)'
                                : (request.donationStatus == 'not_completed'
                                      ? 'DID NOT HAPPEN'
                                      : 'DONOR ACCEPTED'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: request.isDonationCompleted
                                  ? const Color(0xFF15803D)
                                  : (request.donationStatus == 'not_completed'
                                        ? const Color(0xFFDC2626)
                                        : kAdminBlue),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        RequesterAvatar(
                          userId: request.donorId,
                          photoUrl: request.donorPhotoUrl,
                          name: request.donorName,
                          radius: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.displayDonorName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kTextDark,
                                ),
                              ),
                              Text(
                                'Blood: ${request.donorBloodGroup ?? 'N/A'} • Phone: ${request.donorPhone ?? 'Not provided'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (request.acceptedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Accepted at: ${DateFormat('MMM dd, yyyy - hh:mm a').format(request.acceptedAt!)}',
                        style: const TextStyle(fontSize: 10, color: kHintGrey),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: onReject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CA3AF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAdminBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Approve & Publish',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: request.isApproved
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: request.isApproved ? kAdminBlue : kCriticalText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (request.isRejected)
                    ElevatedButton.icon(
                      onPressed: onRepublish,
                      icon: const Icon(Icons.replay, size: 16),
                      label: const Text('Republish Request'),
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
                    )
                  else if (request.isApproved)
                    TextButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      label: const Text('Withdraw'),
                      style: TextButton.styleFrom(
                        foregroundColor: kCriticalText,
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
