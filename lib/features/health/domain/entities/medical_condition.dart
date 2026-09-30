class MedicalCondition {
  const MedicalCondition({
    required this.conditionId,
    required this.petId,
    required this.name,
    required this.status,
    required this.source,
    required this.diagnosisDate,
    this.vetId,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String conditionId;
  final String petId;
  final String name;
  final String status;
  final String source;
  final DateTime diagnosisDate;
  final String? vetId;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
