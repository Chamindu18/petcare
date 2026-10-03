import '../entities/medical_condition.dart';
import '../repositories/medical_condition_repository.dart';

class GetMedicalConditions {
  const GetMedicalConditions(this._repository);

  final MedicalConditionRepository _repository;

  Future<List<MedicalCondition>> call(String petId) {
    return _repository.getMedicalConditions(petId);
  }
}
