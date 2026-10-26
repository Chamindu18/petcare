import '../../domain/entities/veterinarian.dart';

/// Converts Firestore veterinarian data into a domain Veterinarian.
class VeterinarianModel extends Veterinarian {
  const VeterinarianModel({
    required super.vetId,
    required super.hospitalId,
    required super.name,
    super.profileImageUrl,
    super.specialty,
    super.qualifications,
    super.experienceYears,
    super.bio,
    required super.active,
  });

  /// Creates a VeterinarianModel from Firestore data.
  factory VeterinarianModel.fromMap(Map<String, dynamic> map) {
    return VeterinarianModel(
      vetId: map['vetId'] as String,
      hospitalId: map['hospitalId'] as String,
      name: map['name'] as String,
      profileImageUrl: map['profileImageUrl'] as String?,
      specialty: map['specialty'] as String?,
      qualifications: map['qualifications'] as String?,
      experienceYears: (map['experienceYears'] as num?)?.toInt(),
      bio: map['bio'] as String?,
      active: map['active'] as bool,
    );
  }

  /// Converts the model into Firestore-compatible data.
  Map<String, dynamic> toMap() {
    return {
      'vetId': vetId,
      'hospitalId': hospitalId,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'specialty': specialty,
      'qualifications': qualifications,
      'experienceYears': experienceYears,
      'bio': bio,
      'active': active,
    };
  }
}
