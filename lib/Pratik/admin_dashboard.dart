import 'package:flutter/material.dart';
import '../Manob/auth_service.dart';
import 'admin_login.dart';
import 'admin_nav.dart';
import 'admin_service.dart';
import 'admin_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminDashboardStats? _lastKnownStats;
  late Stream<AdminDashboardStats> _statsStream;

  @override
  void initState() {
    super.initState();
    _statsStream = AdminService.streamDashboardStats();
  }

  void _retry() {
    setState(() {
      _statsStream = AdminService.streamDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AdminBottomBar(currentIndex: 0),
      body: SafeArea(
        child: StreamBuilder<AdminDashboardStats>(
          stream: _statsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _lastKnownStats = snapshot.data;
            }

            // Error state when no cached data exists
            if (snapshot.hasError && _lastKnownStats == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 64,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to Load Dashboard Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A query error occurred: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: kTextMuted),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAdminBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final stats = _lastKnownStats ?? AdminDashboardStats();
            final hasSyncError = snapshot.hasError && _lastKnownStats != null;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/lifelink_full_logo.png',
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Row(
                          children: [
                            Icon(Icons.water_drop, color: kAdminBlue, size: 36),
                            SizedBox(width: 8),
                            Text(
                              'LifeLink',
                              style: TextStyle(
                                color: kAdminBlue,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasSyncError) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Connection issue — displaying cached statistics.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: _retry,
                            color: const Color(0xFFDC2626),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time system oversight and donor management',
                    style: TextStyle(fontSize: 14, color: kTextMuted),
                  ),
                  const SizedBox(height: 20),

                  // TOTAL DONORS CARD (Real-time)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: adminCardDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL DONORS',
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 0.6,
                                  color: kHintGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${stats.totalDonors}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: kAdminBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.favorite, color: kAdminBlue, size: 56),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // MINI STAT CARDS (Real-time)
                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          label: 'PENDING REQUESTS',
                          value: '${stats.pendingRequests}',
                          valueColor: kAdminOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          label: 'ACTIVE USERS',
                          value: '${stats.totalUsers}',
                          valueColor: kTextDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          label: 'AVAILABLE DONORS',
                          value: '${stats.availableDonors}',
                          valueColor: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          label: 'VERIFIED DONATIONS',
                          value: '${stats.verifiedDonations}',
                          valueColor: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          label: 'UNITS DONATED',
                          value: '${stats.totalVerifiedUnits} U',
                          valueColor: kAdminBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          label: 'APPROVED REQUESTS',
                          value: '${stats.approvedRequests}',
                          valueColor: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'Control Center',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ControlCard(
                    title: 'Manage Donors',
                    subtitle: 'Update blood types & eligibility',
                    onTap: () => AdminNav.toTab(context, 1),
                  ),
                  const SizedBox(height: 10),
                  _ControlCard(
                    title: 'Blood Requests',
                    subtitle: 'Review, approve, and publish requests',
                    onTap: () => AdminNav.toTab(context, 2),
                  ),
                  const SizedBox(height: 10),
                  _ControlCard(
                    title: 'System Alerts & Audit',
                    subtitle: 'Review operational logs and notifications',
                    onTap: () => AdminNav.toTab(context, 3),
                  ),
                  const SizedBox(height: 10),
                  _ControlCard(
                    title: 'Manage Users & Donations',
                    subtitle: 'Manage donor records and donation verification',
                    onTap: () => AdminNav.toTab(context, 4),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        await AuthService.logout();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminLogin(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAdminBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'LOGOUT FROM ADMIN SESSION',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              color: kHintGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: adminCardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: kTextMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kHintGrey),
            ],
          ),
        ),
      ),
    );
  }
}
