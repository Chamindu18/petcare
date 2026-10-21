import '../entities/ai_pet_context.dart';

class GenerateLocalPreventiveCare {
  const GenerateLocalPreventiveCare();

  String call(AIPetContext context) {
    final dueVaccinations = context.vaccinations
        .where((v) => v.nextDueDate != null)
        .length;

    return '''
Vaccination Records:
${context.vaccinations.length}

Upcoming Vaccination Reviews:
$dueVaccinations

Medical Conditions:
${context.conditions.length}

Health Measurements:
${context.measurements.length}

Continue monitoring health records
and vaccination schedules regularly.
''';
  }
}
