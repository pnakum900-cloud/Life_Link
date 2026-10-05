import 'package:flutter/material.dart';
import 'user_nav.dart';

class Alerts extends StatelessWidget {
  const Alerts({super.key});

  static const _notifications = [
    {'status': 'Normal', 'title': 'Normal Request at Rajkot Civil Hospital', 'blood': 'Blood Type AB+'},
    {'status': 'Normal', 'title': 'Normal Request at Rajkot Civil Hospital', 'blood': 'Blood Type AB+'},
    {'status': 'Normal', 'title': 'Normal Request at Rajkot Civil Hospital', 'blood': 'Blood Type AB+'},
    {'status': 'Urgent', 'title': 'Urgent Request at Rajkot Civil Hospital', 'blood': 'Blood Type AB+'},
    {'status': 'Normal', 'title': 'Normal Request at Rajkot Civil Hospital', 'blood': 'Blood Type AB+'},
    {'status': 'Normal', 'title': 'Normal Request at Rajkot Civil Hospital', 'blood': 'Blood Type AB+'},
    {'status': 'Normal', 'title': 'Normal Request at Rajkot Civil Hospital', 'blood': 'Blood Type AB+'},
    {'status': 'Critical', 'title': 'Critical Request at Rajkot Civil Hospital', 'blood': 'Blood Type AB+'},
  ];

  Color _badgeColor(String status) {
    switch (status) {
      case 'Urgent':
        return const Color(0xFFFECACA);
      case 'Critical':
        return const Color(0xFFDBEAFE);
      default:
        return const Color(0xFFBBF7D0);
    }
  }

  Color _badgeText(String status) {
    switch (status) {
      case 'Urgent':
        return const Color(0xFFB91C1C);
      case 'Critical':
        return kUserBlue;
      default:
        return const Color(0xFF15803D);
    }
  }

  void _openDetails(BuildContext context, Map<String, String> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notification Details'),
          content: Text('${item['title']}.\n${item['blood']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: kUserDark,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  return InkWell(
                    onTap: () => _openDetails(context, item),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kUserBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _badgeColor(item['status']!),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              item['status']!,
                              style: TextStyle(
                                color: _badgeText(item['status']!),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kUserMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['blood']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: kUserDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '40 MINUTES AGO',
                            style: TextStyle(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
