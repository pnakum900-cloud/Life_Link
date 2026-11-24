import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Centralized service handling Firebase initialization and instances.
class FirebaseService {
  static bool _initialized = false;
  static bool _hasConfigError = false;
  static String? _initErrorMessage;

  static bool get isInitialized => _initialized;
  static bool get hasConfigError => _hasConfigError;
  static String? get initErrorMessage => _initErrorMessage;

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Initializes Firebase once across the entire application.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _initialized = true;
      _hasConfigError = false;
      _initErrorMessage = null;
      debugPrint('[FirebaseService] Firebase successfully initialized.');
    } catch (e) {
      debugPrint('[FirebaseService] Initialization notice: $e');
      _hasConfigError = true;
      _initErrorMessage = e.toString();
      // Even if platform initialization throws (e.g. dummy keys during initial dev),
      // we record the error and provide clear guidance.
    }
  }
}
