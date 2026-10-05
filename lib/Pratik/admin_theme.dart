import 'package:flutter/material.dart';

/// Shared colors and helpers for the Admin Panel.
const Color kAdminBlue = Color(0xFF0757D5);
const Color kAdminOrange = Color(0xFFC2410C);
const Color kTextDark = Color(0xFF111827);
const Color kTextMuted = Color(0xFF6B7280);
const Color kHintGrey = Color(0xFF9CA3AF);
const Color kBorderGrey = Color(0xFFE5E7EB);
const Color kCardFill = Colors.white;
const Color kCriticalBg = Color(0xFFFDECEC);
const Color kCriticalText = Color(0xFFDC2626);
const Color kBadgeGreen = Color(0xFF4ADE80);
const Color kBadgePink = Color(0xFFF9C5D5);

InputDecoration adminInputDecoration({
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: kHintGrey,
      fontSize: 13,
      letterSpacing: 0.4,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorderGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kAdminBlue, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
    counterText: '',
  );
}

BoxDecoration adminCardDecoration({Color? color}) {
  return BoxDecoration(
    color: color ?? kCardFill,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: kBorderGrey),
  );
}
