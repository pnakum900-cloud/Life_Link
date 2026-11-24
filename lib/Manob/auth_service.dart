import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Bokul/donor_model.dart';
import 'app_validators.dart';
import 'email_validator.dart';
import 'firebase_service.dart';
import 'user_model.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final bool isEmailUnverified;
  final bool isProfileMissing;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.isEmailUnverified = false,
    this.isProfileMissing = false,
  });
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  static User? get currentFirebaseUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Step 1 of Secure Registration:
  /// Validates input, creates pending Firebase Auth credentials, and dispatches
  /// an email verification link.
  ///
  /// CRITICAL SECURITY REQUIREMENT:
  /// NEVER creates active 'users/{uid}' or 'donor_profiles/{uid}' Firestore records
  /// before the user's email is verified.
  static Future<AuthResult> initiateRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String bloodGroup,
    String address = '150 Feet Ring Road, Rajkot',
    String city = 'Rajkot',
  }) async {
    // 1. Rigorous input validation
    final nameErr = AppValidators.validateName(fullName);
    if (nameErr != null) return AuthResult(success: false, message: nameErr);

    final emailErr = AppValidators.validateEmail(email);
    if (emailErr != null) return AuthResult(success: false, message: emailErr);

    final phoneErr = AppValidators.validatePhone(phoneNumber);
    if (phoneErr != null) return AuthResult(success: false, message: phoneErr);

    final passErr = AppValidators.validatePassword(
      password,
      isNewPassword: true,
    );
    if (passErr != null) return AuthResult(success: false, message: passErr);

    final bloodErr = AppValidators.validateBloodGroup(bloodGroup);
    if (bloodErr != null) return AuthResult(success: false, message: bloodErr);

    final normalizedEmail = EmailValidator.normalize(email);

    try {
      // 2. Create pending Firebase Authentication account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return AuthResult(
          success: false,
          message: 'Account creation failed: User is null.',
        );
      }

      await firebaseUser.updateDisplayName(fullName.trim());

      // 3. Send official Firebase verification email
      await firebaseUser.sendEmailVerification();

      // No Firestore documents written yet. The user remains in pending unverified state.
      return AuthResult(
        success: true,
        isEmailUnverified: true,
        message:
            'Verification link sent to $normalizedEmail. Please verify your email to activate your account.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseAuthErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Step 2 of Secure Registration:
  /// Called after the user clicks the verification link in their email.
  /// Reloads the Auth user, refreshes ID token claims, and creates the active
  /// Firestore profile only when `emailVerified == true`.
  static Future<AuthResult> completeRegistrationAfterVerification({
    required String fullName,
    required String bloodGroup,
    required String phoneNumber,
    String address = '150 Feet Ring Road, Rajkot',
    String city = 'Rajkot',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthResult(
        success: false,
        message: 'No active session found. Please log in.',
      );
    }

    try {
      // 1. Reload user state from Firebase servers
      await user.reload();
      final freshUser = _auth.currentUser ?? user;

      // 2. Verify email claim
      if (!freshUser.emailVerified) {
        return AuthResult(
          success: false,
          isEmailUnverified: true,
          message:
              'Email is not yet verified. Please click the link sent to ${freshUser.email}.',
        );
      }

      // 3. Force refresh ID token so security rules receive `token.email_verified == true`
      await freshUser.getIdToken(true);

      final uid = freshUser.uid;
      final now = DateTime.now();
      final normalizedEmail = freshUser.email ?? '';
      final resolvedCity = AppValidators.resolveCity(city);
      final resolvedAddress = address.trim().isNotEmpty
          ? address.trim()
          : '150 Feet Ring Road, Rajkot';

      // 4. Initialize verified Firestore user document
      final userModel = UserModel(
        uid: uid,
        fullName: fullName.trim(),
        email: normalizedEmail,
        phoneNumber: phoneNumber.trim(),
        role: 'user', // Strict user role
        accountStatus: 'active',
        createdAt: now,
        updatedAt: now,
      );

      // 5. Initialize verified Firestore donor document
      final donorModel = DonorModel(
        userId: uid,
        fullName: fullName.trim(),
        bloodGroup: bloodGroup.trim().toUpperCase(),
        phoneNumber: phoneNumber.trim(),
        address: resolvedAddress,
        city: resolvedCity,
        isAvailable: true,
        eligibilityStatus: 'READY',
        role: 'user',
        totalDonationCount: 0,
        totalUnitsDonated: 0,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(uid), userModel.toMap());
      batch.set(
        _firestore.collection('donor_profiles').doc(uid),
        donorModel.toMap(),
      );

      await batch.commit();

      return AuthResult(
        success: true,
        user: userModel,
        message: 'Registration completed and email verified successfully!',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to complete registration: ${e.toString()}',
      );
    }
  }

  /// Resends verification email to the current authenticated user with rate-limiting safety.
  static Future<AuthResult> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthResult(
        success: false,
        message: 'No active account session found. Please log in first.',
      );
    }

    try {
      await user.sendEmailVerification();
      return AuthResult(
        success: true,
        message:
            'Verification link resent to ${user.email}. Check your inbox and spam folder.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return AuthResult(
          success: false,
          message: 'Too many requests. Please wait a moment before resending.',
        );
      }
      return AuthResult(
        success: false,
        message: _getFirebaseAuthErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Could not send verification email: ${e.toString()}',
      );
    }
  }

  /// Backward-compatible registration helper.
  static Future<AuthResult> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String bloodGroup,
    String address = '150 Feet Ring Road, Rajkot',
    String city = 'Rajkot',
    String role = 'user',
  }) async {
    return initiateRegistration(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      bloodGroup: bloodGroup,
      address: address,
      city: city,
    );
  }

  /// Logs in a user using Firebase Authentication and validates their profile.
  ///
  /// Enforces:
  /// 1. Domain validation (@gmail.com, @rku.ac.in).
  /// 2. User reload & email verification verification.
  /// 3. Rejection of unverified accounts.
  /// 4. ID token claim refresh.
  /// 5. Valid existing Firestore profile check. NEVER silently recreates deleted/missing accounts.
  /// 6. Account status check ('active' required; 'suspended'/'disabled' blocked).
  static Future<AuthResult> login({
    required String email,
    required String password,
    bool requireAdminRole = false,
  }) async {
    final normalizedEmail = EmailValidator.normalize(email);

    if (!EmailValidator.isValid(normalizedEmail)) {
      return AuthResult(
        success: false,
        message: 'Only @gmail.com and @rku.ac.in emails are allowed.',
      );
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return AuthResult(
          success: false,
          message: 'Authentication failed: User is null.',
        );
      }

      // Reload fresh verification state from Firebase Authentication
      await firebaseUser.reload();
      final freshUser = _auth.currentUser ?? firebaseUser;

      // Check email verification status
      if (!freshUser.emailVerified) {
        return AuthResult(
          success: false,
          isEmailUnverified: true,
          message:
              'Your email address (${freshUser.email}) is not verified yet. Please check your inbox or resend the verification link.',
        );
      }

      // Refresh token claims so Firestore rules have latest email_verified claim
      await freshUser.getIdToken(true);

      // Fetch user profile from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(freshUser.uid)
          .get();

      if (!userDoc.exists) {
        // DO NOT silently recreate deleted or missing profile!
        // Sign out to prevent unlinked session access.
        await _auth.signOut();
        return AuthResult(
          success: false,
          isProfileMissing: true,
          message:
              'Account profile not found or has been removed. Please register or contact support.',
        );
      }

      final userModel = UserModel.fromFirestore(userDoc);

      // Check account status
      if (userModel.accountStatus == 'disabled' ||
          userModel.accountStatus == 'suspended') {
        await _auth.signOut();
        return AuthResult(
          success: false,
          message:
              'This account has been ${userModel.accountStatus}. Please contact support.',
        );
      }

      // If logging into admin panel, verify admin role
      if (requireAdminRole && userModel.role != 'admin') {
        await _auth.signOut();
        return AuthResult(
          success: false,
          message: 'Access denied: You do not have administrator privileges.',
        );
      }

      return AuthResult(success: true, user: userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseAuthErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Login failed: $e');
    }
  }

  /// Logs out the currently authenticated user.
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Gets the currently authenticated user's profile from Firestore.
  static Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  static String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email address or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password (at least 8 characters with letters & numbers).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few moments and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
