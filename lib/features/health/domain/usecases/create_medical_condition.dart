import '../entities/medical_condition.dart';
import '../repositories/medical_condition_repository.dart';

class CreateMedicalCondition {
  const CreateMedicalCondition(this._repository);

  final MedicalConditionRepository _repository;

  Future<MedicalCondition> call(MedicalCondition condition) {
    return _repository.createMedicalCondition(condition);
  }
}
