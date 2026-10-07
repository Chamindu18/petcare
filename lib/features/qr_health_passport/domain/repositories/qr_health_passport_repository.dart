import '../entities/qr_health_passport.dart';

///  how QR health passport references are accessed
abstract interface class QrHealthPassportRepository {
  // Create a secure QR reference for an appointment.
  Future<QrHealthPassport> createQrReference({
    required String petId,
    required String appointmentId,
  });

  // Verify a QR reference before allowing access.
  Future<QrHealthPassport?> verifyQrReference(String token);
}
