import 'package:flutter/material.dart';
import 'admin_nav.dart';
import 'admin_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AdminBottomBar(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 28),
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
                'System oversight and donor management',
                style: TextStyle(fontSize: 14, color: kTextMuted),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: adminCardDecoration(),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL DONORS',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.6,
                              color: kHintGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '10',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: kAdminBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.favorite, color: kAdminBlue, size: 56),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _StatMiniCard(
                      label: 'PENDING REQUESTS',
                      value: '5',
                      valueColor: kAdminOrange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatMiniCard(
                      label: 'ACTIVE USERS',
                      value: '10',
                      valueColor: kTextDark,
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
                subtitle: 'Review and fulfill urgent requests',
                onTap: () => AdminNav.toTab(context, 2),
              ),
              const SizedBox(height: 10),
              _ControlCard(
                title: 'Manage Users',
                subtitle: 'Permissions and role management',
                onTap: () => AdminNav.toTab(context, 4),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Replace this with real logout logic later
                    AdminNav.logout(context);
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
