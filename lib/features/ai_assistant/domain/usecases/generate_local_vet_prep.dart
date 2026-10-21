import '../entities/ai_pet_context.dart';

class GenerateLocalVetPrep {
  const GenerateLocalVetPrep();

  String call(AIPetContext context) {
    return '''
Pet: ${context.pet.name}

Conditions: ${context.conditions.length}

Treatments: ${context.treatments.length}

Measurements: ${context.measurements.length}

Prepare discussion around these records before the appointment.
''';
  }
}
