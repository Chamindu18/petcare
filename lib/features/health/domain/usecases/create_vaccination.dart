import '../entities/vaccination.dart';
import '../repositories/vaccination_repository.dart';

class CreateVaccination {
  const CreateVaccination(this._repository);

  final VaccinationRepository _repository;

  Future<Vaccination> call(Vaccination vaccination) {
    return _repository.createVaccination(vaccination);
  }
}
