import 'dart:convert';
import 'package:flutter/material.dart';
import '../Manob/auth_service.dart';
import '../Manob/home_screen.dart';
import '../Manob/user_model.dart';
import 'alerts.dart';
import 'profile.dart';
import 'request.dart';
import 'search.dart';
import 'user_service.dart';

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
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
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
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Request'),
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

/// Renders an avatar image from either a Base64 data URI / string or a network URL,
/// falling back automatically to a default person icon on failure or empty input.
Widget buildAvatarImage(
  String? urlOrBase64,
  double effectiveSize, {
  Color? fallbackColor,
}) {
  final iconColor = fallbackColor ?? kUserBlue;
  final defaultIcon = Center(
    child: Icon(Icons.person, color: iconColor, size: effectiveSize * 0.55),
  );

  if (urlOrBase64 == null || urlOrBase64.trim().isEmpty) {
    return defaultIcon;
  }

  final clean = urlOrBase64.trim();

  // Check if string is base64 encoded image data (e.g. data:image/jpeg;base64,...)
  if (clean.startsWith('data:image') ||
      (!clean.startsWith('http://') &&
          !clean.startsWith('https://') &&
          clean.length > 80)) {
    try {
      final base64Part = clean.contains(',') ? clean.split(',').last : clean;
      final bytes = base64Decode(base64Part);
      return Image.memory(
        bytes,
        width: effectiveSize,
        height: effectiveSize,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => defaultIcon,
      );
    } catch (_) {
      return defaultIcon;
    }
  }

  // Standard network image
  return Image.network(
    clean,
    width: effectiveSize,
    height: effectiveSize,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Center(
        child: SizedBox(
          width: effectiveSize * 0.4,
          height: effectiveSize * 0.4,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    },
    errorBuilder: (_, _, _) => defaultIcon,
  );
}

/// Reactive avatar for the authenticated user that updates in real time
/// across all screens whenever their profile picture changes.
class UserAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({super.key, this.size = 36, this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentFirebaseUser?.uid ?? '';
    if (uid.isEmpty) {
      return _buildFallback();
    }

    return StreamBuilder<String?>(
      stream: UserService.streamUserProfilePhoto(uid),
      builder: (context, photoSnapshot) {
        return StreamBuilder<UserModel?>(
          stream: UserService.streamUser(uid),
          builder: (context, userSnapshot) {
            final photoData =
                photoSnapshot.data ??
                userSnapshot.data?.profileImageUrl ??
                AuthService.currentFirebaseUser?.photoURL;

            return GestureDetector(
              onTap: onTap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: kUserBorder),
                ),
                child: ClipOval(
                  child: buildAvatarImage(
                    photoData,
                    size,
                    fallbackColor: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF3F4F6),
        border: Border.all(color: kUserBorder),
      ),
      child: Icon(
        Icons.person,
        color: const Color(0xFF9CA3AF),
        size: size * 0.55,
      ),
    );
  }
}

/// Display avatar for any requester or donor with fallback to person icon.
class RequesterAvatar extends StatelessWidget {
  final String? userId;
  final String? photoUrl;
  final String? name;
  final double size;
  final double? radius;

  const RequesterAvatar({
    super.key,
    this.userId,
    this.photoUrl,
    this.name,
    this.size = 44,
    this.radius,
  });

  Widget _buildAvatar(String? resolvedPhoto, double effectiveSize) {
    return Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFDBEAFE),
        border: Border.all(color: kUserBorder),
      ),
      child: ClipOval(
        child: buildAvatarImage(resolvedPhoto, effectiveSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = radius != null ? radius! * 2 : size;
    final uid = userId?.trim() ?? '';

    // Use the dedicated profile_photos document as the live source of truth.
    // This also refreshes old request cards after a user changes their photo.
    if (uid.isEmpty) {
      return _buildAvatar(photoUrl, effectiveSize);
    }

    return StreamBuilder<String?>(
      stream: UserService.streamUserProfilePhoto(uid),
      builder: (context, snapshot) {
        final savedPhoto = snapshot.data;
        final resolvedPhoto =
            (savedPhoto != null && savedPhoto.trim().isNotEmpty)
            ? savedPhoto
            : photoUrl;
        return _buildAvatar(resolvedPhoto, effectiveSize);
      },
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
        UserAvatar(
          size: 36,
          onTap: onProfileTap ?? () => goUserTab(context, -1, 4),
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
