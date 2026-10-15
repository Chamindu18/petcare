import '../entities/vaccination.dart';

abstract interface class VaccinationRepository {
  Future<Vaccination> createVaccination(Vaccination vaccination);

  Future<List<Vaccination>> getVaccinations(String petId);

  Future<Vaccination?> getVaccinationById(String petId, String vaccinationId);

  Future<void> updateVaccination(Vaccination vaccination);

  Future<void> deleteVaccination(String petId, String vaccinationId);
}
