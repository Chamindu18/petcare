import '../entities/ai_pet_context.dart';

class GenerateLocalVetPrep {
  const GenerateLocalVetPrep();

  String call(AIPetContext context) {
    return '''
Prepare discussion around:

• ${context.conditions.length} conditions

• ${context.treatments.length} treatments

• ${context.measurements.length} measurements
''';
  }
}
