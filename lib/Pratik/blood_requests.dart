import 'package:flutter/material.dart';
import 'admin_data.dart';
import 'admin_nav.dart';
import 'admin_theme.dart';

class BloodRequests extends StatefulWidget {
  const BloodRequests({super.key});

  @override
  State<BloodRequests> createState() => _BloodRequestsState();
}

class _BloodRequestsState extends State<BloodRequests> {
  List<Map<String, dynamic>> get _requests => AdminData.requests;

  void _setDecision(int id, String decision) {
    setState(() {
      final index = _requests.indexWhere(
        (item) => item['id'] == id,
      );

      if (index != -1) {
        _requests[index]['decision'] = decision;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decision == 'approved'
              ? 'Request approved'
              : 'Request rejected',
        ),
      ),
    );
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFECACA);

      case 'urgent':
        return const Color(0xFFFEF3C7);

      case 'normal':
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB91C1C);

      case 'urgent':
        return const Color(0xFFB45309);

      case 'normal':
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AdminBottomBar(
        currentIndex: 2,
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
                title: 'Manage Blood Request',
              ),

              const SizedBox(height: 8),

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
                'Manage urgent blood requirements from regional hospitals.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: kTextMuted,
                ),
              ),

              const SizedBox(height: 18),

              ..._requests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 14,
                  ),
                  child: _RequestCard(
                    request: request,
                    statusBackgroundColor:
                        _getStatusBackgroundColor(
                      request['status'] as String,
                    ),
                    statusTextColor:
                        _getStatusTextColor(
                      request['status'] as String,
                    ),
                    onApprove: () => _setDecision(
                      request['id'] as int,
                      'approved',
                    ),
                    onReject: () => _setDecision(
                      request['id'] as int,
                      'rejected',
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.statusBackgroundColor,
    required this.statusTextColor,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> request;
  final Color statusBackgroundColor;
  final Color statusTextColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final decision = request['decision'] as String;
    final isPending = decision == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  request['status'] as String,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),

              const Spacer(),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    request['bloodType'] as String,
                    style: const TextStyle(
                      color: kAdminBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    request['units'] as String,
                    style: const TextStyle(
                      color: kTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            request['hospital'] as String,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kTextDark,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            request['location'] as String,
            style: const TextStyle(
              color: kTextMuted,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Patient: ${request['patient']}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),

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
                        backgroundColor:
                            const Color(0xFF9CA3AF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
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
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              decision == 'approved'
                  ? 'Approved'
                  : 'Rejected',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: decision == 'approved'
                    ? kAdminBlue
                    : kAdminOrange,
              ),
            ),
        ],
      ),
    );
  }
}