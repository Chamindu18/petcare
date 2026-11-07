import '../../../appointments/domain/entities/appointment.dart';
import '../../../health/domain/entities/health_measurement.dart';
import '../../../health/domain/entities/medical_condition.dart';
import '../../../health/domain/entities/treatment.dart';
import '../../../health/domain/entities/vaccination.dart';

/// Represents a secure QR reference for a pet's health passport.
class QrHealthPassport {
  const QrHealthPassport({
    required this.token,
    required this.petId,
    required this.appointmentId,
    required this.hospitalId,
    required this.veterinarianId,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  final String token;
  final String petId;
  final String appointmentId;
  final String hospitalId;
  final String veterinarianId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status;

  bool get isRevoked => status == 'revoked';
}

/// Read-only data released by a successfully verified QR reference.
class QrHealthPassportData {
  const QrHealthPassportData({
    required this.passport,
    required this.petName,
    required this.species,
    required this.breed,
    required this.dateOfBirth,
    required this.appointment,
    required this.medicalConditions,
    required this.vaccinations,
    required this.treatments,
    required this.measurements,
  });

  final QrHealthPassport passport;
  final String petName;
  final String species;
  final String breed;
  final DateTime dateOfBirth;
  final Appointment appointment;
  final List<MedicalCondition> medicalConditions;
  final List<Vaccination> vaccinations;
  final List<Treatment> treatments;
  final List<HealthMeasurement> measurements;
}

const qrHealthPassportValidity = Duration(minutes: 15);

abstract final class QrHealthPassportPayload {
  static const _prefix = 'petcare://health-passport/';
  static final RegExp _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

  static String encode(String token) => '$_prefix$token';

  static String? decode(String value) {
    final trimmed = value.trim();
    if (!trimmed.startsWith(_prefix)) return null;
    final token = trimmed.substring(_prefix.length);
    return _tokenPattern.hasMatch(token) ? token : null;
  }
}
