import '../entities/ai_pet_context.dart';

class CreateHealthSummaryFromContext {
  const CreateHealthSummaryFromContext();

  String call(AIPetContext context) {
    return '''
Pet Name: ${context.pet.name}

Species: ${context.pet.species}

Breed: ${context.pet.breed}

Age: ${context.pet.ageInYears} years

Weight: ${context.pet.weight} kg

Medical Conditions: ${context.conditions.length}

Vaccinations: ${context.vaccinations.length}

Treatments: ${context.treatments.length}

Measurements: ${context.measurements.length}
''';
  }
}
