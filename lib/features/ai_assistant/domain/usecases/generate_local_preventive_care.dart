import '../entities/ai_pet_context.dart';

class GenerateLocalPreventiveCare {
  const GenerateLocalPreventiveCare();

  String call(AIPetContext context) {
    final dueVaccines = context.vaccinations
        .where((v) => v.nextDueDate != null)
        .length;

    return '''
Vaccination Records: ${context.vaccinations.length}

Upcoming Vaccine Reviews: $dueVaccines

Medical Conditions: ${context.conditions.length}

Health Measurements: ${context.measurements.length}

Preventive recommendations will be generated from these records.
''';
  }
}
