import '../../domain/entities/veterinarian.dart';

/// Converts Firestore veterinarian data into a domain Veterinarian.
class VeterinarianModel extends Veterinarian {
  const VeterinarianModel({
    required super.vetId,
    required super.hospitalId,
    required super.name,
    super.specialty,
    required super.active,
  });

  /// Creates a VeterinarianModel from Firestore data.
  factory VeterinarianModel.fromMap(Map<String, dynamic> map) {
    return VeterinarianModel(
      vetId: map['vetId'] as String,
      hospitalId: map['hospitalId'] as String,
      name: map['name'] as String,
      specialty: map['specialty'] as String?,
      active: map['active'] as bool,
    );
  }

  /// Converts the model into Firestore-compatible data.
  Map<String, dynamic> toMap() {
    return {
      'vetId': vetId,
      'hospitalId': hospitalId,
      'name': name,
      'specialty': specialty,
      'active': active,
    };
  }
}
