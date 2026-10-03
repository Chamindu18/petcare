import '../../domain/entities/treatment.dart';

class TreatmentModel extends Treatment {
  const TreatmentModel({
    required super.treatmentId,
    required super.petId,
    required super.name,
    required super.status,
    required super.source,
    super.startDate,
    super.endDate,
    required super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TreatmentModel.fromMap(Map<String, dynamic> map) {
    return TreatmentModel(
      treatmentId: map['treatmentId'] as String,
      petId: map['petId'] as String,
      name: map['name'] as String,
      status: map['status'] as String,
      source: map['source'] as String,
      startDate: map['startDate'] == null
          ? null
          : DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] == null
          ? null
          : DateTime.parse(map['endDate'] as String),
      notes: map['notes'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  factory TreatmentModel.fromEntity(Treatment treatment) {
    return TreatmentModel(
      treatmentId: treatment.treatmentId,
      petId: treatment.petId,
      name: treatment.name,
      status: treatment.status,
      source: treatment.source,
      startDate: treatment.startDate,
      endDate: treatment.endDate,
      notes: treatment.notes,
      createdAt: treatment.createdAt,
      updatedAt: treatment.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'treatmentId': treatmentId,
      'petId': petId,
      'name': name,
      'status': status,
      'source': source,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
