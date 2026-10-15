import '../repositories/treatment_repository.dart';

class DeleteTreatment {
  const DeleteTreatment(this._repository);

  final TreatmentRepository _repository;

  Future<void> call(String petId, String treatmentId) {
    return _repository.deleteTreatment(petId, treatmentId);
  }
}
