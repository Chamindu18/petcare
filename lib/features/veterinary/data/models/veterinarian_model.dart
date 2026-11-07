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
      name: map['name'] is String ? map['name'] as String : 'Veterinarian',
      profileImageUrl: map['profileImageUrl'] is String
          ? map['profileImageUrl'] as String
          : null,
      specialty: map['specialty'] is String ? map['specialty'] as String : null,
      qualifications: map['qualifications'] is String
          ? map['qualifications'] as String
          : null,
      experienceYears: _experienceYears(map['experienceYears']),
      bio: map['bio'] is String ? map['bio'] as String : null,
      active: map['active'] as bool,
    );
  }

  static int? _experienceYears(Object? value) {
    final number = value is num
        ? value
        : value is String
        ? num.tryParse(value)
        : null;
    return number != null && number.isFinite && number >= 0
        ? number.toInt()
        : null;
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
