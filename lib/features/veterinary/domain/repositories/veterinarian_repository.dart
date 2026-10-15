import '../entities/veterinarian.dart';

/// Defines how the application accesses veterinarian data.
abstract interface class VeterinarianRepository {
  // Get active veterinarians for a specific hospital.
  Future<List<Veterinarian>> getVeterinariansByHospital(String hospitalId);

  // Get one veterinarian by ID.
  Future<Veterinarian?> getVeterinarianById(String vetId);
}
