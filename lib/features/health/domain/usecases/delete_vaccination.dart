import '../repositories/vaccination_repository.dart';

class DeleteVaccination {
  const DeleteVaccination(this._repository);

  final VaccinationRepository _repository;

  Future<void> call(String petId, String vaccinationId) {
    return _repository.deleteVaccination(petId, vaccinationId);
  }
}
