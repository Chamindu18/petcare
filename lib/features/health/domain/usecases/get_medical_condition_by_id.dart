import '../entities/medical_condition.dart';
import '../repositories/medical_condition_repository.dart';

class GetMedicalConditionById {
  const GetMedicalConditionById(this._repository);

  final MedicalConditionRepository _repository;

  Future<MedicalCondition?> call(String petId, String conditionId) {
    return _repository.getMedicalConditionById(petId, conditionId);
  }
}
