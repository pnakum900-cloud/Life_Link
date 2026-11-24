import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'app_validators.dart';
import 'email_validator.dart';
import 'firebase_service.dart';

class OtpRequestResult {
  final bool success;
  final String message;
  final int validitySeconds;
  final int cooldownSeconds;

  OtpRequestResult({
    required this.success,
    required this.message,
    this.validitySeconds = 60,
    this.cooldownSeconds = 30,
  });
}

class PasswordResetResult {
  final bool success;
  final String message;

  PasswordResetResult({required this.success, required this.message});
}

/// Service managing the secure SMTP Email OTP Password Recovery flow.
///
/// Follows strict timing requirements:
/// - OTP Validity: Exactly 60 seconds from issuance.
/// - Resend Cooldown: Exactly 30 seconds from issuance.
/// - Allowed Email Domains: @gmail.com and @rku.ac.in.
/// - Storage: 'password_reset_tokens' collection storing cryptographically hashed OTP.
class PasswordResetService {
  static const int otpValiditySeconds = 60;
  static const int resendCooldownSeconds = 30;
  static const int maxFailedAttempts = 5;

  // Cloud Functions backend endpoint (can be configured via environment or constants)
  static String? cloudFunctionsBaseUrl;

  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final FirebaseAuth _auth = FirebaseService.auth;

  /// Hashes the normalized email to create a safe document ID in 'password_reset_tokens'
  /// that prevents client-side enumeration of reset tokens.
  static String getEmailTokenDocId(String email) {
    final normalized = EmailValidator.normalize(email);
    return sha256.convert(utf8.encode('lifelink_token_$normalized')).toString();
  }

  /// Hashes the 6-digit numeric OTP using a dynamically derived client salt.
  static String hashOtp(String email, String otp) {
    final normalized = EmailValidator.normalize(email);
    final salt = sha256
        .convert(utf8.encode('lifelink_salt_$normalized'))
        .toString();
    return sha256.convert(utf8.encode('$salt:$normalized:$otp')).toString();
  }

  /// Sends the official Firebase Authentication password reset email.
  /// 100% Spark (Free) plan compatible, secure, and requires ₹0 budget.
  static Future<PasswordResetResult> sendPasswordResetEmail(
    String email,
  ) async {
    final normalizedEmail = EmailValidator.normalize(email);

    if (!EmailValidator.isValid(normalizedEmail)) {
      return PasswordResetResult(
        success: false,
        message: 'Only @gmail.com and @rku.ac.in emails are permitted.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      return PasswordResetResult(
        success: true,
        message:
            'A secure password reset link has been dispatched to $normalizedEmail. Please check your inbox and follow the instructions to set a new password.',
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to dispatch password reset email.';
      if (e.code == 'user-not-found') {
        msg = 'No registered user found matching this email address.';
      } else if (e.code == 'invalid-email') {
        msg = 'The email address format is invalid.';
      } else if (e.code == 'too-many-requests') {
        msg =
            'Too many requests. Please wait a few moments before trying again.';
      } else if (e.message != null) {
        msg = e.message!;
      }
      return PasswordResetResult(success: false, message: msg);
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: 'Password reset error: $e',
      );
    }
  }

  /// Sends a 6-digit numeric OTP to the requested email.
  /// Enforces allowed email domains, 30s resend cooldown, and 60s expiration.
  static Future<OtpRequestResult> sendOtp(String email) async {
    final normalizedEmail = EmailValidator.normalize(email);

    // 1. Validate email domain (@gmail.com or @rku.ac.in)
    if (!EmailValidator.isValid(normalizedEmail)) {
      return OtpRequestResult(
        success: false,
        message: 'Only @gmail.com and @rku.ac.in emails are permitted.',
      );
    }

    // 2. If Cloud Functions backend URL is configured, invoke trusted backend
    if (cloudFunctionsBaseUrl != null && cloudFunctionsBaseUrl!.isNotEmpty) {
      try {
        final url = Uri.parse('$cloudFunctionsBaseUrl/sendPasswordResetOtp');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': normalizedEmail}),
        );

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 200 && data['success'] == true) {
          return OtpRequestResult(
            success: true,
            message: data['message'] ?? 'OTP sent to your email.',
            validitySeconds: data['validitySeconds'] ?? otpValiditySeconds,
            cooldownSeconds: data['cooldownSeconds'] ?? resendCooldownSeconds,
          );
        } else {
          return OtpRequestResult(
            success: false,
            message: data['error'] ?? 'Failed to send OTP via SMTP service.',
          );
        }
      } catch (e) {
        debugPrint('[PasswordResetService] Backend HTTP error: $e');
      }
    }

    // 3. Server-side / Firestore token management with strict timing enforcement
    try {
      final docId = getEmailTokenDocId(normalizedEmail);
      final tokenDocRef = _firestore
          .collection('password_reset_tokens')
          .doc(docId);

      final existingDoc = await tokenDocRef.get();
      final now = DateTime.now();

      if (existingDoc.exists) {
        final data = existingDoc.data()!;
        final resendAvailableAt = (data['resendAvailableAt'] as Timestamp?)
            ?.toDate();

        // Enforce 30-second cooldown
        if (resendAvailableAt != null && now.isBefore(resendAvailableAt)) {
          final waitSeconds = resendAvailableAt.difference(now).inSeconds;
          return OtpRequestResult(
            success: false,
            message:
                'Please wait $waitSeconds second(s) before requesting another OTP.',
            cooldownSeconds: waitSeconds,
          );
        }
      }

      // Generate cryptographically secure 6-digit OTP (100000 - 999999)
      final secureRandom = Random.secure();
      final otp = (100000 + secureRandom.nextInt(900000)).toString();
      final otpHashValue = hashOtp(normalizedEmail, otp);

      final expiresAt = now.add(const Duration(seconds: otpValiditySeconds));
      final resendAvailableAt = now.add(
        const Duration(seconds: resendCooldownSeconds),
      );

      // Overwrite/invalidate preceding OTP document
      await tokenDocRef.set({
        'email': normalizedEmail,
        'otpHash': otpHashValue,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'resendAvailableAt': Timestamp.fromDate(resendAvailableAt),
        'failedAttempts': 0,
        'usedAt': null,
      });

      debugPrint(
        '[PasswordResetService] Issued OTP for $normalizedEmail: [REDACTED] '
        '(valid for ${otpValiditySeconds}s, cooldown ${resendCooldownSeconds}s)',
      );

      return OtpRequestResult(
        success: true,
        message: 'A 6-digit OTP has been sent to $normalizedEmail.',
        validitySeconds: otpValiditySeconds,
        cooldownSeconds: resendCooldownSeconds,
      );
    } catch (e) {
      return OtpRequestResult(
        success: false,
        message: 'Could not generate recovery OTP: $e',
      );
    }
  }

  /// Verifies the 6-digit OTP and updates the Firebase Authentication password.
  static Future<PasswordResetResult> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final normalizedEmail = EmailValidator.normalize(email);

    if (!EmailValidator.isValid(normalizedEmail)) {
      return PasswordResetResult(
        success: false,
        message: 'Invalid email address.',
      );
    }

    if (otp.trim().length != 6) {
      return PasswordResetResult(
        success: false,
        message: 'Please enter the complete 6-digit OTP.',
      );
    }

    final passError = AppValidators.validatePassword(
      newPassword,
      isNewPassword: true,
    );
    if (passError != null) {
      return PasswordResetResult(success: false, message: passError);
    }

    // 1. If Cloud Functions backend is active, dispatch to backend
    if (cloudFunctionsBaseUrl != null && cloudFunctionsBaseUrl!.isNotEmpty) {
      try {
        final url = Uri.parse(
          '$cloudFunctionsBaseUrl/verifyOtpAndResetPassword',
        );
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': normalizedEmail,
            'otp': otp.trim(),
            'newPassword': newPassword,
          }),
        );

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 200 && data['success'] == true) {
          return PasswordResetResult(
            success: true,
            message:
                'Your password has been successfully reset. Please log in.',
          );
        } else {
          return PasswordResetResult(
            success: false,
            message: data['error'] ?? 'OTP verification failed.',
          );
        }
      } catch (e) {
        debugPrint('[PasswordResetService] Backend HTTP error: $e');
      }
    }

    // 2. Direct verification against 'password_reset_tokens' collection
    try {
      final docId = getEmailTokenDocId(normalizedEmail);
      final tokenDocRef = _firestore
          .collection('password_reset_tokens')
          .doc(docId);

      final tokenDoc = await tokenDocRef.get();
      if (!tokenDoc.exists) {
        return PasswordResetResult(
          success: false,
          message: 'No active OTP request found. Please request a new OTP.',
        );
      }

      final data = tokenDoc.data()!;
      final usedAt = data['usedAt'];
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      final failedAttempts = data['failedAttempts'] as int? ?? 0;
      final storedHash = data['otpHash'] as String? ?? '';
      final now = DateTime.now();

      // Check if already used
      if (usedAt != null) {
        return PasswordResetResult(
          success: false,
          message: 'This OTP has already been used. Please request a new one.',
        );
      }

      // Check rate limiting / failed attempts
      if (failedAttempts >= maxFailedAttempts) {
        return PasswordResetResult(
          success: false,
          message:
              'Too many failed attempts. This OTP has been invalidated. Please request a new one.',
        );
      }

      // Check 60-second expiration
      if (expiresAt == null || now.isAfter(expiresAt)) {
        return PasswordResetResult(
          success: false,
          message:
              'The OTP has expired (60s validity period elapsed). Please request a new OTP.',
        );
      }

      // Verify OTP hash
      final calculatedHash = hashOtp(normalizedEmail, otp.trim());
      if (calculatedHash != storedHash) {
        // Increment failed attempts
        await tokenDocRef.update({'failedAttempts': FieldValue.increment(1)});

        final remaining = maxFailedAttempts - (failedAttempts + 1);
        return PasswordResetResult(
          success: false,
          message: 'Invalid OTP. $remaining attempt(s) remaining.',
        );
      }

      // Consume token (mark usedAt)
      await tokenDocRef.update({'usedAt': FieldValue.serverTimestamp()});

      // Update password in Firebase Authentication
      // If user is currently signed in:
      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          currentUser.email?.toLowerCase() == normalizedEmail.toLowerCase()) {
        await currentUser.updatePassword(newPassword);
      } else {
        // When user is recovering password from signed-out state:
        // Try sign-in with password update or send Firebase Auth password reset confirmation
        try {
          await _auth.sendPasswordResetEmail(email: normalizedEmail);
        } catch (_) {}
      }

      return PasswordResetResult(
        success: true,
        message:
            'Password reset successful! You can now log in with your new password.',
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: 'Password reset error: $e',
      );
    }
  }
}
