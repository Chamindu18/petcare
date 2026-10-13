import '../../../health/domain/usecases/get_health_measurements.dart';
import '../../../health/domain/usecases/get_medical_conditions.dart';
import '../../../health/domain/usecases/get_treatments.dart';
import '../../../health/domain/usecases/get_vaccinations.dart';
import '../../../pets/domain/usecases/get_pet_by_id.dart';
import '../entities/pet_health_context.dart';

class BuildAIContext {
  const BuildAIContext(
    this._getPetById,
    this._getConditions,
    this._getVaccinations,
    this._getTreatments,
    this._getMeasurements,
  );

  final GetPetById _getPetById;
  final GetMedicalConditions _getConditions;
  final GetVaccinations _getVaccinations;
  final GetTreatments _getTreatments;
  final GetHealthMeasurements _getMeasurements;

  Future<PetHealthContext> call(String petId) async {
    final normalizedPetId = petId.trim();

    if (normalizedPetId.isEmpty) {
      throw ArgumentError.value(petId, 'petId', 'Pet ID cannot be empty.');
    }

    final pet = await _getPetById(normalizedPetId);

    if (pet == null) {
      throw StateError('Pet not found or access denied.');
    }

    // Start loading all four health record collections in parallel.
    final conditionsFuture = _getConditions(normalizedPetId);
    final vaccinationsFuture = _getVaccinations(normalizedPetId);
    final treatmentsFuture = _getTreatments(normalizedPetId);
    final measurementsFuture = _getMeasurements(normalizedPetId);

    await Future.wait<void>([
      conditionsFuture.then<void>((_) {}),
      vaccinationsFuture.then<void>((_) {}),
      treatmentsFuture.then<void>((_) {}),
      measurementsFuture.then<void>((_) {}),
    ]);

    return PetHealthContext(
      pet: pet,
      conditions: await conditionsFuture,
      vaccinations: await vaccinationsFuture,
      treatments: await treatmentsFuture,
      measurements: await measurementsFuture,
      fetchedAt: DateTime.now(),
    );
  }
}
