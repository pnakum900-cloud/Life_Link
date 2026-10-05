import 'package:flutter/material.dart';
import 'user_nav.dart';

class DonationHistory extends StatelessWidget {
  const DonationHistory({super.key});

  static const _timeline = [
    {
      'date': 'July 15, 2023',
      'place': 'Life-Link Blood Bank Default',
      'location': 'Kalavad Road, Rajkot',
    },
    {
      'date': 'July 15, 2023',
      'place': 'Life-Link Blood Bank Default',
      'location': 'Kalavad Road, Rajkot',
    },
    {
      'date': 'July 15, 2023',
      'place': 'Life-Link Blood Bank Default',
      'location': 'Kalavad Road, Rajkot',
    },
    {
      'date': 'March 02, 2023',
      'place': 'Life-Link Blood Bank Default',
      'location': 'Hospital Chowk, Rajkot',
    },
    {
      'date': 'November 20, 2022',
      'place': 'Life-Link Blood Bank Default',
      'location': 'Kalavad Road, Rajkot',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const UserBottomBar(currentIndex: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const UserBackHeader(title: 'DONATION HISTORY'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kUserBorder),
                ),
                child: Column(
                  children: [
                    const Text(
                      'LIFETIME IMPACT',
                      style: TextStyle(
                        color: kUserHint,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '1.8',
                                style: TextStyle(
                                  color: kUserBlue,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'LITER DONATED',
                                style: TextStyle(
                                  color: kUserHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '12',
                                style: TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'LIVES IMPACTED',
                                style: TextStyle(
                                  color: kUserHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'TOTAL: 5 DONATION',
                        style: TextStyle(
                          fontSize: 11,
                          color: kUserMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Timeline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kUserDark,
                ),
              ),
              const SizedBox(height: 12),
              ..._timeline.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kUserBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['date']!,
                          style: const TextStyle(color: kUserHint, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['place']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kUserDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: kUserBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['location']!,
                              style: const TextStyle(color: kUserMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBF7D0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'COMPLETED',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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
