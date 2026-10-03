import '../entities/medical_condition.dart';

abstract interface class MedicalConditionRepository {
  Future<MedicalCondition> createMedicalCondition(MedicalCondition condition);

  Future<List<MedicalCondition>> getMedicalConditions(String petId);

  Future<MedicalCondition?> getMedicalConditionById(
    String petId,
    String conditionId,
  );

  Future<void> updateMedicalCondition(MedicalCondition condition);

  Future<void> deleteMedicalCondition(String petId, String conditionId);
}
