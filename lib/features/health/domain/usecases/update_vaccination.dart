import '../entities/vaccination.dart';
import '../repositories/vaccination_repository.dart';

class UpdateVaccination {
  const UpdateVaccination(this._repository);

  final VaccinationRepository _repository;

  Future<void> call(Vaccination vaccination) {
    return _repository.updateVaccination(vaccination);
  }
}
