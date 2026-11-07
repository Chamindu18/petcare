import '../entities/veterinarian.dart';
import '../repositories/veterinarian_repository.dart';

/// Gets all active veterinarians for doctor discovery.
class GetVeterinarians {
  const GetVeterinarians(this._repository);

  final VeterinarianRepository _repository;

  Future<List<Veterinarian>> call() {
    return _repository.getVeterinarians();
  }
}

/// Gets active veterinarians for a hospital.
class GetVeterinariansByHospital {
  const GetVeterinariansByHospital(this._repository);

  final VeterinarianRepository _repository;

  Future<List<Veterinarian>> call(String hospitalId) {
    return _repository.getVeterinariansByHospital(hospitalId);
  }
}

/// Gets one veterinarian by ID.
class GetVeterinarianById {
  const GetVeterinarianById(this._repository);

  final VeterinarianRepository _repository;

  Future<Veterinarian?> call(String vetId) {
    return _repository.getVeterinarianById(vetId);
  }
}

class UpdateVeterinarianProfile {
  const UpdateVeterinarianProfile(this._repository);

  final VeterinarianRepository _repository;

  Future<void> call({
    required String vetId,
    required String name,
    String? profileImageUrl,
    String? specialty,
    String? qualifications,
    int? experienceYears,
    String? bio,
  }) {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw const VeterinarianProfileValidationException(
        'Name cannot be empty.',
      );
    }

    if (experienceYears != null &&
        (experienceYears < 0 || experienceYears > 80)) {
      throw const VeterinarianProfileValidationException(
        'Experience must be between 0 and 80 years.',
      );
    }

    return _repository.updateVeterinarianProfile(
      vetId: vetId,
      name: normalizedName,
      profileImageUrl: _normalize(profileImageUrl),
      specialty: _normalize(specialty),
      qualifications: _normalize(qualifications),
      experienceYears: experienceYears,
      bio: _normalize(bio),
    );
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();

    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class VeterinarianProfileValidationException implements Exception {
  const VeterinarianProfileValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
