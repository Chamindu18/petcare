import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/features/ai_assistant/domain/entities/pet_health_context.dart';
import '../../../../lib/features/ai_assistant/domain/usecases/build_ai_context.dart';
import '../../../../lib/features/health/domain/entities/health_measurement.dart';
import '../../../../lib/features/health/domain/entities/medical_condition.dart';
import '../../../../lib/features/health/domain/entities/treatment.dart';
import '../../../../lib/features/health/domain/entities/vaccination.dart';
import '../../../../lib/features/health/domain/repositories/health_measurement_repository.dart';
import '../../../../lib/features/health/domain/repositories/medical_condition_repository.dart';
import '../../../../lib/features/health/domain/repositories/treatment_repository.dart';
import '../../../../lib/features/health/domain/repositories/vaccination_repository.dart';
import '../../../../lib/features/health/domain/usecases/get_health_measurements.dart';
import '../../../../lib/features/health/domain/usecases/get_medical_conditions.dart';
import '../../../../lib/features/health/domain/usecases/get_treatments.dart';
import '../../../../lib/features/health/domain/usecases/get_vaccinations.dart';
import '../../../../lib/features/pets/domain/entities/pet.dart';
import '../../../../lib/features/pets/domain/repositories/pet_repository.dart';
import '../../../../lib/features/pets/domain/usecases/get_pet_by_id.dart';

void main() {
  group('BuildAIContext', () {
    late Pet pet;

    setUp(() {
      pet = Pet(
        petId: 'pet-1',
        ownerId: 'owner-1',
        name: 'Buddy',
        species: 'Dog',
        breed: 'Labrador',
        dob: DateTime(2022, 1, 1),
        gender: 'Male',
        weight: 12.5,
        imageUrl: '',
        notes: 'Active dog',
        status: 'active',
      );
    });

    test('retrieves and assembles the pet health context', () async {
      final condition = MedicalCondition(
        conditionId: 'condition-1',
        petId: 'pet-1',
        name: 'Skin condition',
        status: 'active',
        source: 'vet_confirmed',
        diagnosisDate: DateTime(2026, 1, 10),
        notes: 'Recorded by veterinarian',
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      );

      final vaccination = Vaccination(
        vaccinationId: 'vaccination-1',
        petId: 'pet-1',
        name: 'Rabies',
        dateGiven: DateTime(2026, 2, 1),
        nextDueDate: DateTime(2027, 2, 1),
        notes: '',
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final treatment = Treatment(
        treatmentId: 'treatment-1',
        petId: 'pet-1',
        name: 'Skin treatment',
        status: 'completed',
        source: 'vet_confirmed',
        notes: '',
        startDate: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 1, 20),
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 20),
      );

      final measurement = HealthMeasurement(
        measurementId: 'measurement-1',
        petId: 'pet-1',
        type: 'weight',
        value: 12.5,
        unit: 'kg',
        recordedAt: DateTime(2026, 3, 1),
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      );

      final useCase = _createUseCase(
        pet: pet,
        conditions: [condition],
        vaccinations: [vaccination],
        treatments: [treatment],
        measurements: [measurement],
      );

      final context = await useCase('pet-1');

      expect(context, isA<PetHealthContext>());
      expect(context.pet, same(pet));
      expect(context.conditions, equals([condition]));
      expect(context.vaccinations, equals([vaccination]));
      expect(context.treatments, equals([treatment]));
      expect(context.measurements, equals([measurement]));

      expect(
        () => context.conditions.add(condition),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => context.vaccinations.add(vaccination),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => context.treatments.add(treatment),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => context.measurements.add(measurement),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('accepts empty health histories', () async {
      final useCase = _createUseCase(pet: pet);

      final context = await useCase('pet-1');

      expect(context.pet, same(pet));
      expect(context.conditions, isEmpty);
      expect(context.vaccinations, isEmpty);
      expect(context.treatments, isEmpty);
      expect(context.measurements, isEmpty);
    });

    test('rejects an empty pet ID', () async {
      final useCase = _createUseCase(pet: pet);

      await expectLater(
        useCase('   '),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Pet ID cannot be empty.',
          ),
        ),
      );
    });

    test('rejects a pet that cannot be retrieved', () async {
      final useCase = _createUseCase();

      await expectLater(
        useCase('pet-1'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Pet not found or access denied.',
          ),
        ),
      );
    });

    test('propagates health retrieval failures', () async {
      final useCase = _createUseCase(
        pet: pet,
        conditionError: Exception('Health retrieval failed'),
      );

      await expectLater(
        useCase('pet-1'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Health retrieval failed'),
          ),
        ),
      );
    });
  });
}

BuildAIContext _createUseCase({
  Pet? pet,
  List<MedicalCondition> conditions = const [],
  List<Vaccination> vaccinations = const [],
  List<Treatment> treatments = const [],
  List<HealthMeasurement> measurements = const [],
  Object? conditionError,
}) {
  return BuildAIContext(
    GetPetById(_FakePetRepository(pet)),
    GetMedicalConditions(
      _FakeMedicalConditionRepository(
        conditions: conditions,
        error: conditionError,
      ),
    ),
    GetVaccinations(_FakeVaccinationRepository(vaccinations)),
    GetTreatments(_FakeTreatmentRepository(treatments)),
    GetHealthMeasurements(_FakeHealthMeasurementRepository(measurements)),
  );
}

class _FakePetRepository implements PetRepository {
  _FakePetRepository(this.pet);

  final Pet? pet;

  @override
  Future<Pet?> getPetById(String petId) async => pet;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMedicalConditionRepository implements MedicalConditionRepository {
  _FakeMedicalConditionRepository({this.conditions = const [], this.error});

  final List<MedicalCondition> conditions;
  final Object? error;

  @override
  Future<List<MedicalCondition>> getMedicalConditions(String petId) async {
    if (error != null) {
      throw error!;
    }
    return conditions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVaccinationRepository implements VaccinationRepository {
  _FakeVaccinationRepository(this.vaccinations);

  final List<Vaccination> vaccinations;

  @override
  Future<List<Vaccination>> getVaccinations(String petId) async => vaccinations;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTreatmentRepository implements TreatmentRepository {
  _FakeTreatmentRepository(this.treatments);

  final List<Treatment> treatments;

  @override
  Future<List<Treatment>> getTreatments(String petId) async => treatments;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHealthMeasurementRepository implements HealthMeasurementRepository {
  _FakeHealthMeasurementRepository(this.measurements);

  final List<HealthMeasurement> measurements;

  @override
  Future<List<HealthMeasurement>> getHealthMeasurements(String petId) async =>
      measurements;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
