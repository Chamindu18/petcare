import '../../domain/entities/hospital.dart';

/// Converts Firestore hospital data into a domain Hospital.
class HospitalModel extends Hospital {
  const HospitalModel({
    required super.hospitalId,
    required super.name,
    required super.location,
    required super.contact,
    required super.hours,
    required super.active,
  });

  /// Creates a HospitalModel from Firestore data.
  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    return HospitalModel(
      hospitalId: map['hospitalId'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      contact: map['contact'] as String,
      hours: map['hours'] as String,
      active: map['active'] as bool,
    );
  }

  /// Converts the model into Firestore-compatible data.
  Map<String, dynamic> toMap() {
    return {
      'hospitalId': hospitalId,
      'name': name,
      'location': location,
      'contact': contact,
      'hours': hours,
      'active': active,
    };
  }
}
