import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  static Future<void>? _googleInitialization;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
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

      await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Google Sign-In was cancelled.');
      }

      throw AuthException(_googleSignInErrorMessage(error.code));
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthErrorMessage(error.code));
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
      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'user-not-found':
        return 'No account was found with this email.';

      case 'wrong-password':
        return 'The email or password is incorrect.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
