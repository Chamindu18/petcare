import '../entities/ai_pet_context.dart';

class GenerateLocalHealthSummary {
  const GenerateLocalHealthSummary();

  String call(AIPetContext context) {
    final activeConditions = context.conditions
        .where((c) => c.status.toLowerCase() == 'active')
        .length;

    return '''
Pet Name: ${context.pet.name}

Species: ${context.pet.species}

Breed: ${context.pet.breed}

Age: ${context.pet.ageInYears} years

Weight: ${context.pet.weight} kg

Medical Conditions: ${context.conditions.length}

Active Conditions: $activeConditions

Vaccinations: ${context.vaccinations.length}

Treatments: ${context.treatments.length}

Health Measurements: ${context.measurements.length}
''';
  }
}
