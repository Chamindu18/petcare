import '../entities/vaccination.dart';
import '../repositories/vaccination_repository.dart';

class GetVaccinationById {
  const GetVaccinationById(this._repository);

  final VaccinationRepository _repository;

  Future<Vaccination?> call(String petId, String vaccinationId) {
    return _repository.getVaccinationById(petId, vaccinationId);
  }
}
