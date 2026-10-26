import '../entities/ai_pet_context.dart';

class GeneratePetOverview {
  const GeneratePetOverview();

  Map<String, dynamic> call(AIPetContext context) {
    return {
      'petName': context.pet.name,
      'species': context.pet.species,
      'breed': context.pet.breed,
      'age': context.pet.ageInYears,
      'weight': context.pet.weight,

      'conditionCount': context.conditions.length,
      'vaccinationCount': context.vaccinations.length,
      'treatmentCount': context.treatments.length,
      'measurementCount': context.measurements.length,

      'activeConditions': context.conditions
          .where((c) => c.status.toLowerCase() == 'active')
          .length,
    };
  }
}
