import '../../domain/entities/qr_health_passport.dart';

/// Converts QR reference data into a domain entity.
class QrHealthPassportModel extends QrHealthPassport {
  const QrHealthPassportModel({
    required super.token,
    required super.petId,
    required super.appointmentId,
    required super.expiresAt,
  });

  /// Creates a model from stored data.
  factory QrHealthPassportModel.fromMap(Map<String, dynamic> map) {
    return QrHealthPassportModel(
      token: map['token'] as String,
      petId: map['petId'] as String,
      appointmentId: map['appointmentId'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  /// Converts the model into storable data.
  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'petId': petId,
      'appointmentId': appointmentId,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
