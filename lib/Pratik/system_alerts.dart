import 'package:flutter/material.dart';
import 'admin_data.dart';
import 'admin_nav.dart';
import 'admin_theme.dart';

class SystemAlerts extends StatefulWidget {
  const SystemAlerts({super.key});

  @override
  State<SystemAlerts> createState() => _SystemAlertsState();
}

class _SystemAlertsState extends State<SystemAlerts> {
  List<Map<String, dynamic>> get _alerts => AdminData.alerts;

  void _removeAlert(int id) {
    setState(() {
      _alerts.removeWhere((alert) => alert['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AdminBottomBar(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            children: [
              const AdminTopBar(title: 'System Alerts'),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCriticalBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Critical Alerts',
                            style: TextStyle(
                              color: kCriticalText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '03 ',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: kCriticalText,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Active',
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
                      child: const Column(
                        children: [
                          Text(
                            'Resolved Today',
                            style: TextStyle(
                              color: kTextMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '12 ',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: kAdminBlue,
                                  ),
                                ),
                                TextSpan(
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
              ),

              const SizedBox(height: 16),

              if (_alerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No alerts right now.'),
                )
              else
                ..._alerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AlertCard(
                      alert: alert,
                      onView: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Opening blood requests...',
                            ),
                          ),
                        );

                        AdminNav.toTab(context, 2);
                      },
                      onClose: () => _removeAlert(
                        alert['id'] as int,
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onView,
    required this.onClose,
  });

  final Map<String, dynamic> alert;
  final VoidCallback onView;
  final VoidCallback onClose;

  Color _getBadgeBackgroundColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'normal':
        return const Color(0xFFE5E7EB);

      case 'urgent':
        return const Color(0xFFFEF3C7);

      case 'critical':
        return const Color(0xFFFEE2E2);

      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color _getBadgeTextColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'normal':
        return const Color(0xFF4B5563);

      case 'urgent':
        return const Color(0xFFB45309);

      case 'critical':
        return const Color(0xFFB91C1C);

      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgency = alert['badge'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getBadgeBackgroundColor(urgency),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  urgency,
                  style: TextStyle(
                    color: _getBadgeTextColor(urgency),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                alert['time'] as String,
                style: const TextStyle(
                  color: kHintGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            alert['title'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: kTextDark,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            alert['description'] as String,
            style: const TextStyle(
              color: kTextMuted,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: onView,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAdminBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                height: 42,
                width: 48,
                child: OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(
                      color: kBorderGrey,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: kHintGrey,
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