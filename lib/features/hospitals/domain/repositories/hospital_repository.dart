import '../entities/hospital.dart';

abstract interface class HospitalRepository {
  // Get all active hospitals available to the owner
  Future<List<Hospital>> getHospitals();

  // Get one hospital by its ID
  Future<Hospital?> getHospitalById(String hospitalId);
}
