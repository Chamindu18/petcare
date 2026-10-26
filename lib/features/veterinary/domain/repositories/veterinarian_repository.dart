import '../entities/veterinarian.dart';

/// Defines how the application accesses veterinarian data.
abstract interface class VeterinarianRepository {
  /// Gets all active veterinarians for doctor discovery.
  Future<List<Veterinarian>> getVeterinarians();

  /// Gets active veterinarians for a specific hospital.
  Future<List<Veterinarian>> getVeterinariansByHospital(String hospitalId);

  /// Gets one active veterinarian by ID.
  Future<Veterinarian?> getVeterinarianById(String vetId);
}
