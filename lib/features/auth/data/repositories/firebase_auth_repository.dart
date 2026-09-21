import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static Future<void>? _googleInitialization;

  // Web OAuth client ID from the Firebase project's
  // google-services.json.
  static const String _googleServerClientId =
      '265273949414-jvgg24gdvb1003uioum1sasnjp6tl716.apps.googleusercontent.com';

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize(
      serverClientId: _googleServerClientId,
    );
  }

  @override
  Future<void> registerOwner({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw const AuthException('Account creation failed. Please try again.');
      }

      final normalizedFullName = fullName.trim();
      final normalizedEmail = email.trim();
      final normalizedPhone = phone.trim();

      await user.updateDisplayName(normalizedFullName);

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': normalizedFullName,
        'displayName': normalizedFullName,
        'email': normalizedEmail,
        'phone': normalizedPhone,
        'role': 'owner',
        'notificationEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.reload();
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthErrorMessage(error.code));
    } on FirebaseException catch (error) {
      // Auth user was created but the Firestore profile failed.
      // Attempt cleanup so we do not leave a partially-created account.
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {
          // Cleanup can fail when Firebase requires recent authentication.
        }
      }

      throw AuthException(_firestoreErrorMessage(error.code));
    }
  }

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthErrorMessage(error.code));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    debugPrint('============================================');
    debugPrint('PETCARE+ GOOGLE SIGN-IN STARTED');
    debugPrint('============================================');

    try {
      // ---------------------------------------------------------------
      // Step 1: Initialize Google Sign-In
      // ---------------------------------------------------------------
      debugPrint('GOOGLE AUTH STEP 1: Initializing Google Sign-In...');

      await _ensureGoogleSignInInitialized();

      debugPrint('GOOGLE AUTH STEP 1: Initialization completed.');

      // ---------------------------------------------------------------
      // Step 2: Check platform support
      // ---------------------------------------------------------------
      debugPrint('GOOGLE AUTH STEP 2: Checking authenticate() support...');

      final supportsAuthenticate = _googleSignIn.supportsAuthenticate();

      debugPrint(
        'GOOGLE AUTH STEP 2: supportsAuthenticate=$supportsAuthenticate',
      );

      if (!supportsAuthenticate) {
        throw const AuthException(
          'Google Sign-In is not supported on this platform.',
        );
      }

      // ---------------------------------------------------------------
      // Step 3: Authenticate with Google
      // ---------------------------------------------------------------
      debugPrint('GOOGLE AUTH STEP 3: Calling GoogleSignIn.authenticate()...');

      final googleUser = await _googleSignIn.authenticate();

      debugPrint(
        'GOOGLE AUTH STEP 3: Google authentication returned successfully.',
      );

      debugPrint(
        'GOOGLE AUTH STEP 3: Google account email=${googleUser.email}',
      );

      // ---------------------------------------------------------------
      // Step 4: Get Google authentication token
      // ---------------------------------------------------------------
      debugPrint('GOOGLE AUTH STEP 4: Reading Google authentication token...');

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      debugPrint(
        'GOOGLE AUTH STEP 4: ID token received='
        '${idToken != null && idToken.isNotEmpty}',
      );

      // IMPORTANT:
      // Never print the actual ID token to logs.
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Google Sign-In did not return a valid authentication token.',
        );
      }

      // ---------------------------------------------------------------
      // Step 5: Create Firebase credential
      // ---------------------------------------------------------------
      debugPrint('GOOGLE AUTH STEP 5: Creating Firebase Google credential...');

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      debugPrint('GOOGLE AUTH STEP 5: Firebase credential created.');

      // ---------------------------------------------------------------
      // Step 6: Sign in to Firebase Authentication
      // ---------------------------------------------------------------
      debugPrint(
        'GOOGLE AUTH STEP 6: Calling Firebase signInWithCredential()...',
      );

      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint(
        'GOOGLE AUTH STEP 6: Firebase signInWithCredential() succeeded.',
      );

      final user = userCredential.user;

      if (user == null) {
        throw const AuthException('Google account could not be loaded.');
      }

      debugPrint('GOOGLE AUTH STEP 6: Firebase user UID=${user.uid}');

      debugPrint('GOOGLE AUTH STEP 6: Firebase user email=${user.email}');

      // ---------------------------------------------------------------
      // Step 7: Load/create Firestore owner profile
      // ---------------------------------------------------------------
      debugPrint('GOOGLE AUTH STEP 7: Checking Firestore owner profile...');

      final profileRef = _firestore.collection('users').doc(user.uid);

      final existingProfile = await profileRef.get();

      debugPrint(
        'GOOGLE AUTH STEP 7: Existing profile='
        '${existingProfile.exists}',
      );

      if (!existingProfile.exists) {
        debugPrint('GOOGLE AUTH STEP 7: Creating new owner profile...');

        await profileRef.set({
          'uid': user.uid,
          'fullName': user.displayName ?? '',
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'role': 'owner',
          'notificationEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('GOOGLE AUTH STEP 7: Owner profile created.');
      } else {
        debugPrint('GOOGLE AUTH STEP 7: Updating existing owner profile...');

        await profileRef.update({'updatedAt': FieldValue.serverTimestamp()});

        debugPrint('GOOGLE AUTH STEP 7: Owner profile updated.');
      }

      debugPrint('============================================');
      debugPrint('PETCARE+ GOOGLE SIGN-IN SUCCESS');
      debugPrint('============================================');
    } on GoogleSignInException catch (error, stackTrace) {
      debugPrint('============================================');
      debugPrint('GOOGLE SIGN-IN EXCEPTION');
      debugPrint('============================================');
      debugPrint('Google error code: ${error.code}');
      debugPrint('Google error message: ${error.description}');
      debugPrint('Google error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Google Sign-In was cancelled.');
      }

      throw AuthException(_googleSignInErrorMessage(error.code));
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('============================================');
      debugPrint('GOOGLE FIREBASE AUTH ERROR');
      debugPrint('============================================');
      debugPrint('Firebase Auth error code: ${error.code}');
      debugPrint('Firebase Auth error message: ${error.message}');
      debugPrint('Firebase Auth error plugin: ${error.plugin}');
      debugPrint('Firebase Auth error: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Temporary diagnostic message.
      throw AuthException('Google authentication failed: ${error.code}');
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('============================================');
      debugPrint('GOOGLE FIREBASE ERROR');
      debugPrint('============================================');
      debugPrint('Firebase error code: ${error.code}');
      debugPrint('Firebase error message: ${error.message}');
      debugPrint('Firebase error plugin: ${error.plugin}');
      debugPrint('Firebase error: $error');
      debugPrintStack(stackTrace: stackTrace);

      throw AuthException(_firestoreErrorMessage(error.code));
    } catch (error, stackTrace) {
      debugPrint('============================================');
      debugPrint('GOOGLE UNKNOWN ERROR');
      debugPrint('============================================');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrint('Error: $error');
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://petcare-d4413.firebaseapp.com/reset-password',
        handleCodeInApp: true,
        androidPackageName: 'com.petcareplus.app',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );

      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthErrorMessage(error.code));
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthErrorMessage(error.code));
    }
  }

  String _googleSignInErrorMessage(GoogleSignInExceptionCode code) {
    switch (code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google Sign-In was cancelled.';

      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google Sign-In is not configured correctly.';

      case GoogleSignInExceptionCode.interrupted:
        return 'Google Sign-In was interrupted. Please try again.';

      default:
        return 'Unable to sign in with Google. Please try again.';
    }
  }

  String _firebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Please choose a stronger password.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'No account was found with this email.';

      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'wrong-password':
        return 'The email or password is incorrect.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';

      case 'expired-action-code':
        return 'This password reset link has expired.';

      case 'invalid-action-code':
        return 'This password reset link is invalid.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';

      case 'credential-already-in-use':
        return 'This Google account is already linked to another account.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _firestoreErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Your account could not be saved. Please try again.';

      case 'unavailable':
        return 'The service is temporarily unavailable.';

      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';

      default:
        return 'Your profile could not be saved. Please try again.';
    }
  }
}
