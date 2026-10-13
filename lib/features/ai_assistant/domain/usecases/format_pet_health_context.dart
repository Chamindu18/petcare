import '../entities/pet_health_context.dart';

class FormatPetHealthContext {
  const FormatPetHealthContext();

  String call(PetHealthContext context) {
    final pet = context.pet;
    final sections = <String>[
      'PET PROFILE',
      'Name: ${_display(pet.name)}',
      'Species: ${_display(pet.species)}',
      'Breed: ${_display(pet.breed)}',
      'Date of birth: ${_formatDate(pet.dob)}',
      'Age: ${pet.ageInYears} years',
      'Gender: ${_display(pet.gender)}',
      'Profile weight value: ${pet.weight} (unit not stored in pet profile)',
      'Pet status: ${_display(pet.status)}',
      'Profile notes: ${_display(pet.notes)}',
      '',
      'MEDICAL CONDITIONS',
      if (context.conditions.isEmpty)
        'No medical conditions recorded.'
      else
        ...context.conditions.map(
          (condition) => [
            'Name: ${_display(condition.name)}',
            'Status: ${_display(condition.status)}',
            'Source: ${_display(condition.source)}',
            'Diagnosis date: ${_formatDate(condition.diagnosisDate)}',
            'Notes: ${_display(condition.notes)}',
          ].join('\n'),
        ),
      '',
      'VACCINATION HISTORY',
      if (context.vaccinations.isEmpty)
        'No vaccinations recorded.'
      else
        ...context.vaccinations.map(
          (vaccination) => [
            'Name: ${_display(vaccination.name)}',
            'Date given: ${_formatDate(vaccination.dateGiven)}',
            'Next due date: ${_formatDate(vaccination.nextDueDate)}',
            'Notes: ${_display(vaccination.notes)}',
          ].join('\n'),
        ),
      '',
      'TREATMENT HISTORY',
      if (context.treatments.isEmpty)
        'No treatments recorded.'
      else
        ...context.treatments.map(
          (treatment) => [
            'Name: ${_display(treatment.name)}',
            'Status: ${_display(treatment.status)}',
            'Source: ${_display(treatment.source)}',
            'Start date: ${_formatDate(treatment.startDate)}',
            'End date: ${_formatDate(treatment.endDate)}',
            'Notes: ${_display(treatment.notes)}',
          ].join('\n'),
        ),
      '',
      'HEALTH MEASUREMENTS',
      if (context.measurements.isEmpty)
        'No health measurements recorded.'
      else
        ...context.measurements.map(
          (measurement) => [
            'Type: ${_display(measurement.type)}',
            'Value: ${measurement.value} ${_display(measurement.unit)}',
            'Recorded at: ${_formatDate(measurement.recordedAt)}',
          ].join('\n'),
        ),
      '',
      'Context retrieval time: ${context.fetchedAt.toIso8601String()}',
    ];

    return sections.join('\n');
  }

  String _display(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Not recorded' : trimmed;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not recorded';
    }

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
