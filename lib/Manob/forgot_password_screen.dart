import 'package:flutter/material.dart';
import 'app_validators.dart';
import 'password_reset_service.dart';

class ForgotPassword extends StatefulWidget {
  final bool isAdmin;
  const ForgotPassword({super.key, this.isAdmin = false});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  static const Color _blue = Color(0xFF0757D5);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final result = await PasswordResetService.sendPasswordResetEmail(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Reset Link Sent',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'A password reset link has been dispatched to $email.\n\nPlease check your inbox (and spam folder) and follow the link to reset your password.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Back to Login'),
              ),
            ],
          );
        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: _blue, size: 36),
                    const SizedBox(width: 8),
                    Text(
                      widget.isAdmin ? 'LifeLink Admin' : 'LifeLink',
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 56),

                Text(
                  widget.isAdmin
                      ? 'Admin Password Recovery'
                      : 'Forgot Password?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Enter your registered email (@gmail.com or @rku.ac.in) to receive a secure password reset link directly to your inbox.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'EMAIL ADDRESS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      AppValidators.validateEmail(value, fieldLabel: 'Email'),
                  decoration: InputDecoration(
                    hintText: 'ENTER EMAIL (@gmail.com or @rku.ac.in)',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendPasswordResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SEND RESET LINK  →',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                Center(
                  child: TextButton(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
