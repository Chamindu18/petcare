import '../entities/medical_condition.dart';
import '../repositories/medical_condition_repository.dart';

class UpdateMedicalCondition {
  const UpdateMedicalCondition(this._repository);

  final MedicalConditionRepository _repository;

  Future<void> call(MedicalCondition condition) {
    return _repository.updateMedicalCondition(condition);
  }
}
