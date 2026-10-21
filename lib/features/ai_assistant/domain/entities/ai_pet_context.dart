import '../../../pets/domain/entities/pet.dart';
import '../../../health/domain/entities/medical_condition.dart';
import '../../../health/domain/entities/vaccination.dart';
import '../../../health/domain/entities/treatment.dart';
import '../../../health/domain/entities/health_measurement.dart';

class AIPetContext {
  const AIPetContext({
    required this.pet,
    required this.conditions,
    required this.vaccinations,
    required this.treatments,
    required this.measurements,
  });

  final Pet pet;

  final List<MedicalCondition> conditions;
  final List<Vaccination> vaccinations;
  final List<Treatment> treatments;
  final List<HealthMeasurement> measurements;
}
