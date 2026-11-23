import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Pratik/admin_login.dart';
import 'app_validators.dart';
import 'login_screen.dart';
import 'password_reset_service.dart';

class VerifyOTP extends StatefulWidget {
  final String email;
  final bool isAdmin;

  const VerifyOTP({super.key, required this.email, this.isAdmin = false});

  @override
  State<VerifyOTP> createState() => _VerifyOTPState();
}

class _VerifyOTPState extends State<VerifyOTP> {
  static const Color _blue = Color(0xFF0757D5);

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _isSubmitting = false;

  // Exact timing requirements:
  // OTP Validity: 60 seconds
  // Resend Cooldown: 30 seconds
  int _validityRemaining = PasswordResetService.otpValiditySeconds;
  int _cooldownRemaining = PasswordResetService.resendCooldownSeconds;

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _validityRemaining = PasswordResetService.otpValiditySeconds;
    _cooldownRemaining = PasswordResetService.resendCooldownSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_validityRemaining > 0) {
          _validityRemaining--;
        }
        if (_cooldownRemaining > 0) {
          _cooldownRemaining--;
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleResend() async {
    if (_cooldownRemaining > 0) return;

    final result = await PasswordResetService.sendOtp(widget.email);
    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.green),
      );
      // Clear OTP inputs
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      // Reset countdowns to 60s validity and 30s cooldown
      _startTimers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleVerifyAndReset() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit OTP'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_validityRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This OTP has expired (60s validity elapsed). Please resend a new OTP.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final newPassword = _newPasswordController.text;

    final result = await PasswordResetService.verifyOtpAndResetPassword(
      email: widget.email,
      otp: otp,
      newPassword: newPassword,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.green),
      );

      // Redirect to the appropriate login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              widget.isAdmin ? const AdminLogin() : const UserLogin(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resendActive = _cooldownRemaining == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isAdmin ? 'Admin OTP Verification' : 'Verify OTP',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 18),

                // Expiration Countdown Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _validityRemaining > 0
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: _validityRemaining > 0
                            ? _blue
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _validityRemaining > 0
                            ? 'OTP expires in 00:${_validityRemaining.toString().padLeft(2, '0')}'
                            : 'OTP expired (60s elapsed)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _validityRemaining > 0
                              ? _blue
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 6-digit OTP Inputs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _blue,
                              width: 1.6,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onOtpChanged(value, index),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Resend section with 30-second cooldown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive code? ",
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    TextButton(
                      onPressed: resendActive ? _handleResend : null,
                      child: Text(
                        resendActive
                            ? 'Resend OTP'
                            : 'Resend in ${_cooldownRemaining}s',
                        style: TextStyle(
                          color: resendActive ? _blue : const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // New Password Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NEW PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.6,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isPasswordVisible,
                  validator: (value) => AppValidators.validatePassword(
                    value,
                    isNewPassword: true,
                  ),
                  decoration: _fieldDecoration(
                    'Enter new password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CONFIRM NEW PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.6,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmVisible,
                  validator: (value) => AppValidators.validateConfirmPassword(
                    value,
                    _newPasswordController.text,
                  ),
                  decoration: _fieldDecoration(
                    'Confirm new password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () => setState(
                        () => _isConfirmVisible = !_isConfirmVisible,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleVerifyAndReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'RESET PASSWORD',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    widget.isAdmin
                        ? '←  Back to Admin Login'
                        : '←  Back to Login',
                    style: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
