
import '../../domain/entities/qr_health_passport.dart';
import '../../domain/repositories/qr_health_passport_repository.dart';

/// Repository boundary for secure QR health passport operations.
class FirebaseQrHealthPassportRepository
    implements QrHealthPassportRepository {
  @override
  Future<QrHealthPassport> createQrReference({
    required String petId,
    required String appointmentId,
  }) async {
    
    throw UnimplementedError(
      'QR reference creation must be handled by a trusted backend.',
    );
  }

  @override
  Future<QrHealthPassport?> verifyQrReference(String token) async {
    
    throw UnimplementedError(
      'QR reference verification must be handled by a trusted backend.',
    );
  }
}