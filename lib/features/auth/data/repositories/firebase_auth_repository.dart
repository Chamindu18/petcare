import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize();
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

      await user.updateDisplayName(fullName.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.trim(),
        'displayName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'owner',
        'notificationEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.reload();
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthErrorMessage(error.code));
    } on FirebaseException catch (error) {
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {
          // The Auth account may remain if cleanup requires re-auth.
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
    await _ensureGoogleSignInInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthException(
        'Google Sign-In is not supported on this platform.',
      );
    }

    try {
      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Google Sign-In did not return a valid authentication token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user == null) {
        throw const AuthException('Google account could not be loaded.');
      }

      final profileRef = _firestore.collection('users').doc(user.uid);

      final existingProfile = await profileRef.get();

      if (!existingProfile.exists) {
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
      } else {
        await profileRef.update({'updatedAt': FieldValue.serverTimestamp()});
      }
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Google Sign-In was cancelled.');
      }

      throw AuthException(_googleSignInErrorMessage(error.code));
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthErrorMessage(error.code));
    } on FirebaseException catch (error) {
      throw AuthException(_firestoreErrorMessage(error.code));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
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
