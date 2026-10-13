/// Represents a secure QR reference for a pet's health passport.
class QrHealthPassport {
  const QrHealthPassport({
    required this.token,
    required this.petId,
    required this.appointmentId,
    required this.expiresAt,
  });

  final String token;
  final String petId;
  final String appointmentId;
  final DateTime expiresAt;
}
