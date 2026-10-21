import '../entities/ai_pet_context.dart';

class GenerateLocalPreventiveCare {
  const GenerateLocalPreventiveCare();

  String call(AIPetContext context) {
    return '''
Preventive recommendations will be generated using:

• ${context.vaccinations.length} vaccination records

• ${context.conditions.length} medical conditions

• ${context.measurements.length} health measurements
''';
  }
}
