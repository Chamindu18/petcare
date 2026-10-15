import '../entities/veterinarian.dart';
import '../repositories/veterinarian_repository.dart';

/// Gets active veterinarians for a hospital.
class GetVeterinariansByHospital {
  const GetVeterinariansByHospital(this._repository);

  final VeterinarianRepository _repository;

  // Get veterinarians through the repository.
  Future<List<Veterinarian>> call(String hospitalId) {
    return _repository.getVeterinariansByHospital(hospitalId);
  }
}

/// Gets one veterinarian by ID.
class GetVeterinarianById {
  const GetVeterinarianById(this._repository);

  final VeterinarianRepository _repository;

  // Get the selected veterinarian through the repository.
  Future<Veterinarian?> call(String vetId) {
    return _repository.getVeterinarianById(vetId);
  }
}
