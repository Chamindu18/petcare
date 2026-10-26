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
