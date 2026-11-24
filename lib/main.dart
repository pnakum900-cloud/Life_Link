import 'package:flutter/material.dart';
import 'Bokul/alerts.dart';
import 'Bokul/profile.dart';
import 'Bokul/request.dart';
import 'Bokul/search.dart';
import 'Manob/home_screen.dart';
import 'Manob/login_screen.dart';
import 'Manob/splash_screen.dart';
import 'Pratik/admin_dashboard.dart';
import 'Pratik/admin_login.dart';
import 'Pratik/admin_nav.dart';
import 'Pratik/blood_requests.dart';
import 'Pratik/manage_donors.dart';
import 'Pratik/manage_users.dart';
import 'Pratik/system_alerts.dart';
import 'Manob/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0757D5),
          primary: const Color(0xFF0757D5),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        // User routes
        '/user-login': (context) => const UserLogin(),
        '/home': (context) => const HomeScreen(),
        '/search': (context) => const Search(),
        '/request': (context) => const Request(),
        '/alerts': (context) => const Alerts(),
        '/profile': (context) => const Profile(),

        // Admin routes
        '/admin-login': (context) => const AdminLogin(),
        AdminRoutes.dashboard: (context) => const AdminDashboard(),
        AdminRoutes.donors: (context) => const ManageDonors(),
        AdminRoutes.requests: (context) => const BloodRequests(),
        AdminRoutes.alerts: (context) => const SystemAlerts(),
        AdminRoutes.users: (context) => const ManageUsers(),
      },
    );
  }
}
