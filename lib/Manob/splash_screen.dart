import 'dart:async';
import 'package:flutter/material.dart';
import '../Pratik/admin_dashboard.dart';
import 'auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _blue = Color(0xFF0757D5);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  void _navigateNext() {
    _timer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final currentAuthUser = AuthService.currentFirebaseUser;
      if (currentAuthUser != null) {
        try {
          await currentAuthUser.reload();
          await currentAuthUser.getIdToken(true);
        } catch (_) {}

        if (!currentAuthUser.emailVerified) {
          await AuthService.logout();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserLogin()),
          );
          return;
        }

        // Fetch user profile from Firestore to determine destination
        final profile = await AuthService.getCurrentUserProfile();
        if (!mounted) return;

        if (profile != null && profile.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
          return;
        } else if (profile != null && profile.isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          return;
        } else {
          // Profile is missing, deleted, or suspended: sign out
          await AuthService.logout();
        }
      }

      // Default to UserLogin
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserLogin()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'assets/images/lifelink_full_logo.png',
                width: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.water_drop, color: _blue, size: 72),
              ),
              const SizedBox(height: 14),
              const Text(
                'LifeLink',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connecting Donors, Saving Lives',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
              ),
              Spacer(flex: 4),
              LinearProgressIndicator(
                value: null,
                minHeight: 2,
                color: _blue,
                backgroundColor: Color(0xFFE5E7EB),
              ),
              SizedBox(height: 16),
              Text(
                'INITIALISING SECURE CONNECTION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
