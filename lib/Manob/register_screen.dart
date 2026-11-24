import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_validators.dart';
import 'auth_service.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _bloodGroup;

  static const Color _blue = Color(0xFF0757D5);

  static const List<String> _bloodGroups = AppValidators.validBloodGroups;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(
    String hint, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 13,
        letterSpacing: 0.3,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
        ),
      );
      return;
    }

    if (_bloodGroup == null || _bloodGroup!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a blood group')),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _mobileController.text.trim();
    final password = _passwordController.text;
    const defaultCity = AppValidators.defaultCity;
    const defaultAddress = '150 Feet Ring Road, Rajkot';

    // Step 1: Initiate registration and dispatch verification email.
    // Does NOT create active Firestore user or donor documents before email verification.
    final result = await AuthService.initiateRegistration(
      fullName: fullName,
      email: email,
      phoneNumber: phone,
      password: password,
      bloodGroup: _bloodGroup!,
      city: defaultCity,
      address: defaultAddress,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Navigate to dedicated verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: email,
            fullName: fullName,
            phoneNumber: phone,
            bloodGroup: _bloodGroup!,
            city: defaultCity,
            address: defaultAddress,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Registration failed. Try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 0.6,
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w600,
      ),
    );
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
                    Image.asset(
                      'assets/images/lifelink_full_logo.png',
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Row(
                        children: [
                          Icon(Icons.water_drop, color: _blue, size: 36),
                          SizedBox(width: 8),
                          Text(
                            'LifeLink',
                            style: TextStyle(
                              color: _blue,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Please fill in your details to create an account.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),

                const SizedBox(height: 24),

                _label('FULL NAME'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(50)],
                  validator: (value) => AppValidators.validateName(value),
                  decoration: _decoration('ENTER YOUR FULL NAME'),
                ),

                const SizedBox(height: 16),

                _label('EMAIL ADDRESS'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => AppValidators.validateEmail(value),
                  decoration: _decoration(
                    'ENTER EMAIL (@gmail.com or @rku.ac.in)',
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('MOBILE NUMBER'),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) =>
                                AppValidators.validatePhone(value),
                            decoration: _decoration('MOBILE NO.'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('BLOOD GROUP'),

                          const SizedBox(height: 8),

                          DropdownButtonFormField<String>(
                            initialValue: _bloodGroup,
                            isExpanded: true,
                            hint: const Text(
                              'SELECT',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                            ),
                            items: _bloodGroups
                                .map(
                                  (group) => DropdownMenuItem<String>(
                                    value: group,
                                    child: Text(group),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _bloodGroup = value;
                              });
                            },
                            validator: (value) =>
                                AppValidators.validateBloodGroup(value),
                            decoration: _decoration('SELECT').copyWith(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _label('PASSWORD'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  inputFormatters: [LengthLimitingTextInputFormatter(32)],
                  validator: (value) => AppValidators.validatePassword(
                    value,
                    isNewPassword: true,
                  ),
                  decoration: _decoration(
                    '•••••••• (MIN 8 CHARACTERS)',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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
                            'SIGN UP',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                const Center(
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Center(
                  child: Text(
                    'Already have an account, Sign In',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserLogin(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _blue,
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'LOG IN',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
