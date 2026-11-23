import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Manob/auth_service.dart';
import '../Manob/donation_model.dart';
import 'donation_service.dart';
import 'user_nav.dart';

class DonationHistory extends StatelessWidget {
  const DonationHistory({super.key});

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    return DateFormat('MMMM dd, yyyy').format(dt);
  }

  Color _statusBadgeBg(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return const Color(0xFFBBF7D0);
      case 'rejected':
        return const Color(0xFFFECACA);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  Color _statusBadgeText(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return const Color(0xFF15803D);
      case 'rejected':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentFirebaseUser;
    final donorId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const UserBottomBar(currentIndex: 4),
      body: SafeArea(
        child: StreamBuilder<List<DonationModel>>(
          stream: DonationService.streamDonationsForDonor(donorId),
          builder: (context, snapshot) {
            final allDonations = snapshot.data ?? [];
            final verifiedDonations = allDonations
                .where((d) => d.isVerified)
                .toList();

            num totalVerifiedUnits = 0;
            for (final d in verifiedDonations) {
              totalVerifiedUnits += d.unitsDonated;
            }

            final totalLiters = (totalVerifiedUnits * 0.45).toStringAsFixed(1);
            final livesImpacted = (totalVerifiedUnits * 3).toInt();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UserBackHeader(title: 'DONATION HISTORY'),
                  const SizedBox(height: 16),

                  // Lifetime Impact Card (Calculated from authoritative verified records)
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    totalLiters,
                                    style: const TextStyle(
                                      color: kUserBlue,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
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
                                    '$livesImpacted',
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
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
                          child: Text(
                            'TOTAL: ${verifiedDonations.length} VERIFIED DONATION(S)',
                            style: const TextStyle(
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

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (allDonations.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kUserBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            color: kUserHint,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No donation records yet.',
                            style: TextStyle(
                              color: kUserDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Once you donate and an admin verifies your record, it will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kUserMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ...allDonations.map(
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
                              Row(
                                children: [
                                  Text(
                                    _formatDate(
                                      item.donationDate ?? item.createdAt,
                                    ),
                                    style: const TextStyle(
                                      color: kUserHint,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${item.unitsDonated} Unit(s)',
                                    style: const TextStyle(
                                      color: kUserBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.hospitalName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: kUserDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Patient: ${item.patientName} • Requester: ${item.requesterName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kUserMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.bloodtype,
                                    size: 16,
                                    color: Color(0xFFB91C1C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Blood Group: ${item.bloodGroup}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kUserMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.rejectionReason != null &&
                                  item.rejectionReason!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Reason: ${item.rejectionReason}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB91C1C),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBadgeBg(item.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.isVerified
                                      ? 'VERIFIED DONATION'
                                      : (item.isPendingVerification
                                            ? 'PENDING ADMIN VERIFICATION'
                                            : item.status
                                                  .replaceAll('_', ' ')
                                                  .toUpperCase()),
                                  style: TextStyle(
                                    color: _statusBadgeText(item.status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
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
            );
          },
        ),
      ),
    );
  }
}
