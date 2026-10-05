import 'package:flutter/material.dart';
import '../Manob/home_screen.dart';
import 'alerts.dart';
import 'profile.dart';
import 'request.dart';
import 'search.dart';

const Color kUserBlue = Color(0xFF0757D5);
const Color kUserMuted = Color(0xFF6B7280);
const Color kUserHint = Color(0xFF9CA3AF);
const Color kUserBorder = Color(0xFFE5E7EB);
const Color kUserDark = Color(0xFF111827);

void goUserTab(BuildContext context, int fromIndex, int toIndex) {
  if (fromIndex == toIndex) return;

  if (toIndex == 0) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
    return;
  }

  late final Widget page;
  switch (toIndex) {
    case 1:
      page = const Search();
      break;
    case 2:
      page = const Request();
      break;
    case 3:
      page = const Alerts();
      break;
    default:
      page = const Profile();
  }

  if (fromIndex == 0) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

class UserBottomBar extends StatelessWidget {
  const UserBottomBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: kUserBlue,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: (index) => goUserTab(context, currentIndex, index),
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
          label: 'Request',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class LifeLinkHeader extends StatelessWidget {
  const LifeLinkHeader({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.water_drop, color: kUserBlue, size: 34),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'LifeLink',
            style: TextStyle(
              color: kUserBlue,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        GestureDetector(
          onTap: onProfileTap ??
              () => goUserTab(context, -1, 4),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: Border.all(color: kUserBorder),
            ),
            child: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
          ),
        ),
      ],
    );
  }
}

class UserBackHeader extends StatelessWidget {
  const UserBackHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: kUserBlue,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kUserBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

InputDecoration userFieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: kUserHint,
      fontSize: 13,
      letterSpacing: 0.3,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kUserBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kUserBlue),
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
