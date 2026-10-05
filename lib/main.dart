import 'package:flutter/material.dart';
import 'Manob/home_screen.dart';
import 'Pratik/admin_dashboard.dart';
import 'Pratik/admin_nav.dart';
import 'Pratik/blood_requests.dart';
import 'Pratik/manage_donors.dart';
import 'Pratik/manage_users.dart';
import 'Pratik/system_alerts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life-Link',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomeScreen(),
      routes: {
        AdminRoutes.dashboard: (context) => const AdminDashboard(),
        AdminRoutes.donors: (context) => const ManageDonors(),
        AdminRoutes.requests: (context) => const BloodRequests(),
        AdminRoutes.alerts: (context) => const SystemAlerts(),
        AdminRoutes.users: (context) => const ManageUsers(),
      },
    );
  }
}