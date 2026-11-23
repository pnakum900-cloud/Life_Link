import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink/Manob/password_reset_service.dart';

void main() {
  group('PasswordResetService Tests', () {
    test('Constants meet strict requirements', () {
      expect(PasswordResetService.otpValiditySeconds, 60);
      expect(PasswordResetService.resendCooldownSeconds, 30);
      expect(PasswordResetService.maxFailedAttempts, 5);
    });

    test('Safe document ID derivation prevents email enumeration', () {
      final docId1 = PasswordResetService.getEmailTokenDocId(
        'student@gmail.com',
      );
      final docId2 = PasswordResetService.getEmailTokenDocId(
        'student@rku.ac.in',
      );
      final docId1Normalized = PasswordResetService.getEmailTokenDocId(
        'STUDENT@GMAIL.COM',
      );

      expect(docId1.isNotEmpty, isTrue);
      expect(docId2.isNotEmpty, isTrue);
      expect(docId1, isNot(equals(docId2)));
      expect(docId1, equals(docId1Normalized));
      expect(docId1.contains('@'), isFalse);
    });

    test('OTP hashing is cryptographically secure and deterministic', () {
      final hash1 = PasswordResetService.hashOtp('student@gmail.com', '123456');
      final hash2 = PasswordResetService.hashOtp('student@gmail.com', '123456');
      final hashDiffOtp = PasswordResetService.hashOtp(
        'student@gmail.com',
        '654321',
      );
      final hashDiffEmail = PasswordResetService.hashOtp(
        'faculty@rku.ac.in',
        '123456',
      );

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hashDiffOtp)));
      expect(hash1, isNot(equals(hashDiffEmail)));
      expect(hash1.length, 64); // SHA-256 output length
    });
  });
}
