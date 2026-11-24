import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String phoneNumber;
  final String bloodGroup;
  final String address;
  final String city;
  final bool isFromLogin;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.fullName = '',
    this.phoneNumber = '',
    this.bloodGroup = 'O+',
    this.address = '150 Feet Ring Road, Rajkot',
    this.city = 'Rajkot',
    this.isFromLogin = false,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color _blue = Color(0xFF0757D5);

  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _startAutoCheck();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startAutoCheck() {
    _periodicCheckTimer?.cancel();
    // Auto-detect verification every 4 seconds in background
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 4), (
      timer,
    ) async {
      if (!mounted || _isChecking) return;
      final user = AuthService.currentFirebaseUser;
      if (user == null) {
        timer.cancel();
        return;
      }
      try {
        await user.reload();
        if (user.emailVerified) {
          timer.cancel();
          _verifyAndProceed(isAuto: true);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyAndProceed({bool isAuto = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final user = AuthService.currentFirebaseUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isChecking = false);
        _goToLogin('Session expired. Please log in.');
        return;
      }

      await user.reload();
      if (!user.emailVerified) {
        if (!mounted) return;
        setState(() => _isChecking = false);
        if (!isAuto) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email is not yet verified. Please tap the verification link sent to your inbox and try again.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // If user came from pending registration, finalize Firestore profile
      if (!widget.isFromLogin && widget.fullName.isNotEmpty) {
        final regRes = await AuthService.completeRegistrationAfterVerification(
          fullName: widget.fullName,
          bloodGroup: widget.bloodGroup,
          phoneNumber: widget.phoneNumber,
          address: widget.address,
          city: widget.city,
        );

        if (!mounted) return;
        setState(() => _isChecking = false);

        if (regRes.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email verified successfully! Welcome to LifeLink.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(regRes.message ?? 'Failed to finalize profile.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        // User came from login screen and just verified
        await user.getIdToken(true);
        if (!mounted) return;
        setState(() => _isChecking = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Logging in...'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification check failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);

    final res = await AuthService.resendVerificationEmail();

    if (!mounted) return;
    setState(() => _isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.message ??
              'Verification link sent. Check your inbox & spam folder.',
        ),
        backgroundColor: res.success ? Colors.green : Colors.redAccent,
      ),
    );

    if (res.success) {
      _startCooldown();
    }
  }

  void _goToLogin([String? message]) async {
    await AuthService.logout();
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const UserLogin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => _goToLogin(),
        ),
        title: const Text(
          'Email Verification',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/images/lifelink_full_logo.png',
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.water_drop, color: _blue, size: 56),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: _blue,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email Address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'A verification link has been sent to:\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _blue,
                        fontSize: 15,
                      ),
                    ),
                    const TextSpan(
                      text:
                          '\n\nPlease open your email and tap the link to activate your LifeLink account.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFB45309),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Can\'t find the email? Check your Spam or Junk folder. It may take up to a minute to arrive.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Button: "I've Verified My Email"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : () => _verifyAndProceed(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'I\'VE VERIFIED MY EMAIL',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Button: "Resend Verification Email"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: (_cooldownSeconds == 0 && !_isResending)
                      ? _resendEmail
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _blue,
                          ),
                        )
                      : Text(
                          _cooldownSeconds > 0
                              ? 'Resend Email in ${_cooldownSeconds}s'
                              : 'Resend Verification Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _cooldownSeconds > 0
                                ? const Color(0xFF9CA3AF)
                                : _blue,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Back to Login link
              TextButton(
                onPressed: () => _goToLogin(),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
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
