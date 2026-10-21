import '../entities/ai_pet_context.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../health/domain/entities/medical_condition.dart';
import '../../../health/domain/entities/vaccination.dart';
import '../../../health/domain/entities/treatment.dart';
import '../../../health/domain/entities/health_measurement.dart';

class BuildPetContext {
  const BuildPetContext();

  AIPetContext call({
    required Pet pet,
    required List<MedicalCondition> conditions,
    required List<Vaccination> vaccinations,
    required List<Treatment> treatments,
    required List<HealthMeasurement> measurements,
  }) {
    return AIPetContext(
      pet: pet,
      conditions: conditions,
      vaccinations: vaccinations,
      treatments: treatments,
      measurements: measurements,
    );
  }
}
