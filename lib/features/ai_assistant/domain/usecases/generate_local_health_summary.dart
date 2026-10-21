import '../entities/ai_pet_context.dart';

class GenerateLocalHealthSummary {
  const GenerateLocalHealthSummary();

  String call(AIPetContext context) {
    return '''
Pet Name: ${context.pet.name}

Species: ${context.pet.species}

Breed: ${context.pet.breed}

Medical Conditions: ${context.conditions.length}

Vaccinations: ${context.vaccinations.length}

Treatments: ${context.treatments.length}

Health Measurements: ${context.measurements.length}
''';
  }
}
