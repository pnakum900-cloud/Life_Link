import 'package:flutter/material.dart';
import 'admin_login.dart';
import 'admin_theme.dart';

/// Named routes used by the Admin Panel.
class AdminRoutes {
  static const login = '/';
  static const dashboard = '/admin-dashboard';
  static const donors = '/manage-donors';
  static const requests = '/blood-requests';
  static const alerts = '/system-alerts';
  static const users = '/manage-users';

  static const List<String> tabs = [
    dashboard,
    donors,
    requests,
    alerts,
    users,
  ];
}

/// Bottom-tab and logout navigation for the Admin Panel.
class AdminNav {
  static void toTab(BuildContext context, int index) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AdminRoutes.tabs[index],
      (route) => false,
    );
  }

  static void toDashboard(BuildContext context) {
    toTab(context, 0);
  }

  static void logout(BuildContext context) {
    // TODO: Replace this with real logout logic later
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLogin()),
      (route) => false,
    );
  }
}

/// Shared bottom navigation used on every admin screen after login.
class AdminBottomBar extends StatelessWidget {
  const AdminBottomBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: kAdminBlue,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: (index) {
        if (index == currentIndex) return;
        AdminNav.toTab(context, index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          activeIcon: Icon(Icons.add),
          label: 'Request',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Users',
        ),
      ],
    );
  }
}

/// Top bar with optional back arrow, used on inner admin screens.
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => AdminNav.toDashboard(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: kAdminBlue,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kAdminBlue,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
