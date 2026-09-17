abstract interface class AuthRepository {
  Future<void> registerOwner({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  });
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
