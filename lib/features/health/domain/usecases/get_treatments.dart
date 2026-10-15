import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class GetTreatments {
  const GetTreatments(this._repository);

  final TreatmentRepository _repository;

  Future<List<Treatment>> call(String petId) {
    return _repository.getTreatments(petId);
  }
}
