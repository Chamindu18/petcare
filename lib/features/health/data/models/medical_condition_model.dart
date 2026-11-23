import '../../domain/entities/medical_condition.dart';
import 'stored_health_date.dart';

class MedicalConditionModel extends MedicalCondition {
  const MedicalConditionModel({
    required super.conditionId,
    required super.petId,
    required super.name,
    required super.status,
    required super.source,
    required super.diagnosisDate,
    super.vetId,
    required super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  static MedicalConditionModel? tryFromMap(Map<String, dynamic> map) {
    final diagnosisDate = parseStoredHealthDate(map['diagnosisDate']);
    final createdAt = parseStoredHealthDate(map['createdAt']);
    final updatedAt = parseStoredHealthDate(map['updatedAt']);
    if (diagnosisDate == null || createdAt == null || updatedAt == null) {
      return null;
    }
    return MedicalConditionModel(
      conditionId: map['conditionId'] as String,
      petId: map['petId'] as String,
      name: map['name'] as String,
      status: map['status'] as String,
      source: map['source'] as String,
      diagnosisDate: diagnosisDate,
      vetId: map['vetId'] as String?,
      notes: map['notes'] as String,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory MedicalConditionModel.fromEntity(MedicalCondition condition) {
    return MedicalConditionModel(
      conditionId: condition.conditionId,
      petId: condition.petId,
      name: condition.name,
      status: condition.status,
      source: condition.source,
      diagnosisDate: condition.diagnosisDate,
      vetId: condition.vetId,
      notes: condition.notes,
      createdAt: condition.createdAt,
      updatedAt: condition.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conditionId': conditionId,
      'petId': petId,
      'name': name,
      'status': status,
      'source': source,
      'diagnosisDate': diagnosisDate.toIso8601String(),
      'vetId': vetId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
