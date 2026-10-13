import '../../../health/domain/entities/health_measurement.dart';
import '../../../health/domain/entities/medical_condition.dart';
import '../../../health/domain/entities/treatment.dart';
import '../../../health/domain/entities/vaccination.dart';
import '../../../pets/domain/entities/pet.dart';

class PetHealthContext {
  PetHealthContext({
    required this.pet,
    required List<MedicalCondition> conditions,
    required List<Vaccination> vaccinations,
    required List<Treatment> treatments,
    required List<HealthMeasurement> measurements,
    required this.fetchedAt,
  }) : conditions = List.unmodifiable(conditions),
       vaccinations = List.unmodifiable(vaccinations),
       treatments = List.unmodifiable(treatments),
       measurements = List.unmodifiable(measurements);

  final Pet pet;
  final List<MedicalCondition> conditions;
  final List<Vaccination> vaccinations;
  final List<Treatment> treatments;
  final List<HealthMeasurement> measurements;
  final DateTime fetchedAt;
}
