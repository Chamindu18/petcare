import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/qr_health_passport.dart';

/// Converts QR reference data into a domain entity.
class QrHealthPassportModel extends QrHealthPassport {
  const QrHealthPassportModel({
    required super.token,
    required super.petId,
    required super.appointmentId,
    required super.hospitalId,
    required super.veterinarianId,
    required super.createdAt,
    required super.expiresAt,
    required super.status,
  });

  /// Creates a model from stored data.
  factory QrHealthPassportModel.fromMap(Map<String, dynamic> map) {
    return QrHealthPassportModel(
      token: map['token'] as String,
      petId: map['petId'] as String,
      appointmentId: map['appointmentId'] as String,
      hospitalId: map['hospitalId'] as String,
      veterinarianId: map['veterinarianId'] as String,
      createdAt: _date(map['createdAt']),
      expiresAt: _date(map['createdAt']).add(qrHealthPassportValidity),
      status: map['status'] as String,
    );
  }

  /// Converts the model into storable data.
  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'petId': petId,
      'appointmentId': appointmentId,
      'hospitalId': hospitalId,
      'veterinarianId': veterinarianId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  static DateTime _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    throw const FormatException('Invalid QR passport timestamp.');
  }
}
