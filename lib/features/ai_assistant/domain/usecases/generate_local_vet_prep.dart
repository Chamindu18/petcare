import '../entities/ai_pet_context.dart';

class GenerateLocalVetPrep {
  const GenerateLocalVetPrep();

  String call(AIPetContext context) {
    final activeTreatments = context.treatments
        .where(
          (treatment) =>
              treatment.status.toLowerCase() == 'active' ||
              treatment.status.toLowerCase() == 'ongoing',
        )
        .length;

    final activeConditions = context.conditions
        .where((condition) => condition.status.toLowerCase() == 'active')
        .length;

    return '''
Pet: ${context.pet.name}

Active Conditions:
$activeConditions

Active Treatments:
$activeTreatments

Vaccinations:
${context.vaccinations.length}

Topics to discuss:

• Current medical conditions

• Ongoing treatments

• Recent health measurements

• Vaccination schedule

• Overall health monitoring
''';
  }
}
