import '../entities/ai_pet_context.dart';

class GenerateLocalPreventiveCare {
  const GenerateLocalPreventiveCare();

  String call(AIPetContext context) {
    final dueVaccinations = context.vaccinations
        .where((v) => v.nextDueDate != null)
        .length;

    final overdueVaccinations = context.vaccinations.where((v) {
      if (v.nextDueDate == null) {
        return false;
      }

      return v.nextDueDate!.isBefore(DateTime.now());
    }).length;

    return '''
Vaccination Records:
${context.vaccinations.length}

Vaccinations With Due Dates:
$dueVaccinations

Overdue Vaccinations:
$overdueVaccinations

Medical Conditions:
${context.conditions.length}

Health Measurements:
${context.measurements.length}

Continue monitoring vaccination schedules and health records.
''';
  }
}
