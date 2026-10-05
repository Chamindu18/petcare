import '../entities/vaccination.dart';
import '../repositories/vaccination_repository.dart';

class GetVaccinations {
  const GetVaccinations(this._repository);

  final VaccinationRepository _repository;

  Future<List<Vaccination>> call(String petId) {
    return _repository.getVaccinations(petId);
  }
}
