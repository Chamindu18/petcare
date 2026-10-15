import '../repositories/medical_condition_repository.dart';

class DeleteMedicalCondition {
  const DeleteMedicalCondition(this._repository);

  final MedicalConditionRepository _repository;

  Future<void> call(String petId, String conditionId) {
    return _repository.deleteMedicalCondition(petId, conditionId);
  }
}
