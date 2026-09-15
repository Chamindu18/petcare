abstract interface class AuthRepository {
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
