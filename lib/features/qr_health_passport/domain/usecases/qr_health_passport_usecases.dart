import '../entities/qr_health_passport.dart';
import '../repositories/qr_health_passport_repository.dart';

/// Creates a QR reference for an appointment.
class CreateQrReference {
  const CreateQrReference(this._repository);

  final QrHealthPassportRepository _repository;

  // Delegate secure QR creation to the repository/backend.
  Future<QrHealthPassport> call({
    required String petId,
    required String appointmentId,
  }) {
    return _repository.createQrReference(
      petId: petId,
      appointmentId: appointmentId,
    );
  }
}

/// Verifies a QR reference before accessing health information.
class VerifyQrReference {
  const VerifyQrReference(this._repository);

  final QrHealthPassportRepository _repository;

  // Delegate QR verification to the repository/backend.
  Future<QrHealthPassport?> call(String token) {
    return _repository.verifyQrReference(token);
  }
}

class GetQrHealthPassportData {
  const GetQrHealthPassportData(this._repository);

  final QrHealthPassportRepository _repository;

  Future<QrHealthPassportData> call(String token) {
    return _repository.getPassportData(token);
  }
}

class RevokeQrReference {
  const RevokeQrReference(this._repository);

  final QrHealthPassportRepository _repository;

  Future<void> call(String token) {
    return _repository.revokeQrReference(token);
  }
}
