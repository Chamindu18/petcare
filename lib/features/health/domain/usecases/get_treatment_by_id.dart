import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class GetTreatmentById {
  const GetTreatmentById(this._repository);

  final TreatmentRepository _repository;

  Future<Treatment?> call(String petId, String treatmentId) {
    return _repository.getTreatmentById(petId, treatmentId);
  }
}
