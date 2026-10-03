import '../../domain/entities/vaccination.dart';

class VaccinationModel extends Vaccination {
  const VaccinationModel({
    required super.vaccinationId,
    required super.petId,
    required super.name,
    required super.dateGiven,
    super.nextDueDate,
    super.providerId,
    required super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VaccinationModel.fromMap(Map<String, dynamic> map) {
    return VaccinationModel(
      vaccinationId: map['vaccinationId'] as String,
      petId: map['petId'] as String,
      name: map['name'] as String,
      dateGiven: DateTime.parse(map['dateGiven'] as String),
      nextDueDate: map['nextDueDate'] == null
          ? null
          : DateTime.parse(map['nextDueDate'] as String),
      providerId: map['providerId'] as String?,
      notes: map['notes'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  factory VaccinationModel.fromEntity(Vaccination vaccination) {
    return VaccinationModel(
      vaccinationId: vaccination.vaccinationId,
      petId: vaccination.petId,
      name: vaccination.name,
      dateGiven: vaccination.dateGiven,
      nextDueDate: vaccination.nextDueDate,
      providerId: vaccination.providerId,
      notes: vaccination.notes,
      createdAt: vaccination.createdAt,
      updatedAt: vaccination.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vaccinationId': vaccinationId,
      'petId': petId,
      'name': name,
      'dateGiven': dateGiven.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'providerId': providerId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
