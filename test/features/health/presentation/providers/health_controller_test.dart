import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/health/domain/entities/health_measurement.dart';
import 'package:petcare/features/health/domain/entities/medical_condition.dart';
import 'package:petcare/features/health/domain/entities/treatment.dart';
import 'package:petcare/features/health/domain/entities/vaccination.dart';

import 'package:petcare/features/health/domain/repositories/health_measurement_repository.dart';
import 'package:petcare/features/health/domain/repositories/medical_condition_repository.dart';
import 'package:petcare/features/health/domain/repositories/treatment_repository.dart';
import 'package:petcare/features/health/domain/repositories/vaccination_repository.dart';

import 'package:petcare/features/health/domain/usecases/create_health_measurement.dart';
import 'package:petcare/features/health/domain/usecases/create_medical_condition.dart';
import 'package:petcare/features/health/domain/usecases/create_treatment.dart';
import 'package:petcare/features/health/domain/usecases/create_vaccination.dart';
import 'package:petcare/features/health/domain/usecases/delete_health_measurement.dart';
import 'package:petcare/features/health/domain/usecases/delete_medical_condition.dart';
import 'package:petcare/features/health/domain/usecases/delete_treatment.dart';
import 'package:petcare/features/health/domain/usecases/delete_vaccination.dart';
import 'package:petcare/features/health/domain/usecases/get_health_measurements.dart';
import 'package:petcare/features/health/domain/usecases/get_medical_conditions.dart';
import 'package:petcare/features/health/domain/usecases/get_treatments.dart';
import 'package:petcare/features/health/domain/usecases/get_vaccinations.dart';
import 'package:petcare/features/health/domain/usecases/update_health_measurement.dart';
import 'package:petcare/features/health/domain/usecases/update_medical_condition.dart';
import 'package:petcare/features/health/domain/usecases/update_treatment.dart';
import 'package:petcare/features/health/domain/usecases/update_vaccination.dart';

import 'package:petcare/features/health/presentation/providers/health_controller.dart';

// =============================================================================
// Fake repositories
// =============================================================================

class _FakeMedicalConditionRepository implements MedicalConditionRepository {
  List<MedicalCondition> records = [];

  bool failRead = false;
  bool failCreate = false;
  bool failUpdate = false;
  bool failDelete = false;

  Completer<MedicalCondition>? createGate;

  @override
  Future<MedicalCondition> createMedicalCondition(
    MedicalCondition condition,
  ) async {
    if (failCreate) {
      throw StateError('Medical condition creation failed');
    }

    final gate = createGate;

    if (gate != null) {
      final created = await gate.future;
      records.add(created);
      createGate = null;
      return created;
    }

    records.add(condition);
    return condition;
  }

  @override
  Future<List<MedicalCondition>> getMedicalConditions(String petId) async {
    if (failRead) {
      throw StateError('Medical condition loading failed');
    }

    return records.where((record) => record.petId == petId).toList();
  }

  @override
  Future<MedicalCondition?> getMedicalConditionById(
    String petId,
    String conditionId,
  ) async {
    for (final record in records) {
      if (record.petId == petId && record.conditionId == conditionId) {
        return record;
      }
    }

    return null;
  }

  @override
  Future<void> updateMedicalCondition(MedicalCondition condition) async {
    if (failUpdate) {
      throw StateError('Medical condition update failed');
    }

    final index = records.indexWhere(
      (record) => record.conditionId == condition.conditionId,
    );

    if (index != -1) {
      records[index] = condition;
    }
  }

  @override
  Future<void> deleteMedicalCondition(String petId, String conditionId) async {
    if (failDelete) {
      throw StateError('Medical condition deletion failed');
    }

    records.removeWhere(
      (record) => record.petId == petId && record.conditionId == conditionId,
    );
  }
}

class _FakeVaccinationRepository implements VaccinationRepository {
  List<Vaccination> records = [];

  bool failRead = false;
  bool failCreate = false;
  bool failUpdate = false;
  bool failDelete = false;

  @override
  Future<Vaccination> createVaccination(Vaccination vaccination) async {
    if (failCreate) {
      throw StateError('Vaccination creation failed');
    }

    records.add(vaccination);
    return vaccination;
  }

  @override
  Future<List<Vaccination>> getVaccinations(String petId) async {
    if (failRead) {
      throw StateError('Vaccination loading failed');
    }

    return records.where((record) => record.petId == petId).toList();
  }

  @override
  Future<Vaccination?> getVaccinationById(
    String petId,
    String vaccinationId,
  ) async {
    for (final record in records) {
      if (record.petId == petId && record.vaccinationId == vaccinationId) {
        return record;
      }
    }

    return null;
  }

  @override
  Future<void> updateVaccination(Vaccination vaccination) async {
    if (failUpdate) {
      throw StateError('Vaccination update failed');
    }

    final index = records.indexWhere(
      (record) => record.vaccinationId == vaccination.vaccinationId,
    );

    if (index != -1) {
      records[index] = vaccination;
    }
  }

  @override
  Future<void> deleteVaccination(String petId, String vaccinationId) async {
    if (failDelete) {
      throw StateError('Vaccination deletion failed');
    }

    records.removeWhere(
      (record) =>
          record.petId == petId && record.vaccinationId == vaccinationId,
    );
  }
}

class _FakeTreatmentRepository implements TreatmentRepository {
  List<Treatment> records = [];

  bool failRead = false;
  bool failCreate = false;
  bool failUpdate = false;
  bool failDelete = false;

  @override
  Future<Treatment> createTreatment(Treatment treatment) async {
    if (failCreate) {
      throw StateError('Treatment creation failed');
    }

    records.add(treatment);
    return treatment;
  }

  @override
  Future<List<Treatment>> getTreatments(String petId) async {
    if (failRead) {
      throw StateError('Treatment loading failed');
    }

    return records.where((record) => record.petId == petId).toList();
  }

  @override
  Future<Treatment?> getTreatmentById(String petId, String treatmentId) async {
    for (final record in records) {
      if (record.petId == petId && record.treatmentId == treatmentId) {
        return record;
      }
    }

    return null;
  }

  @override
  Future<void> updateTreatment(Treatment treatment) async {
    if (failUpdate) {
      throw StateError('Treatment update failed');
    }

    final index = records.indexWhere(
      (record) => record.treatmentId == treatment.treatmentId,
    );

    if (index != -1) {
      records[index] = treatment;
    }
  }

  @override
  Future<void> deleteTreatment(String petId, String treatmentId) async {
    if (failDelete) {
      throw StateError('Treatment deletion failed');
    }

    records.removeWhere(
      (record) => record.petId == petId && record.treatmentId == treatmentId,
    );
  }
}

class _FakeHealthMeasurementRepository implements HealthMeasurementRepository {
  List<HealthMeasurement> records = [];

  bool failRead = false;
  bool failCreate = false;
  bool failUpdate = false;
  bool failDelete = false;

  @override
  Future<HealthMeasurement> createHealthMeasurement(
    HealthMeasurement measurement,
  ) async {
    if (failCreate) {
      throw StateError('Health measurement creation failed');
    }

    records.add(measurement);
    return measurement;
  }

  @override
  Future<List<HealthMeasurement>> getHealthMeasurements(String petId) async {
    if (failRead) {
      throw StateError('Health measurement loading failed');
    }

    return records.where((record) => record.petId == petId).toList();
  }

  @override
  Future<HealthMeasurement?> getHealthMeasurementById(
    String petId,
    String measurementId,
  ) async {
    for (final record in records) {
      if (record.petId == petId && record.measurementId == measurementId) {
        return record;
      }
    }

    return null;
  }

  @override
  Future<void> updateHealthMeasurement(HealthMeasurement measurement) async {
    if (failUpdate) {
      throw StateError('Health measurement update failed');
    }

    final index = records.indexWhere(
      (record) => record.measurementId == measurement.measurementId,
    );

    if (index != -1) {
      records[index] = measurement;
    }
  }

  @override
  Future<void> deleteHealthMeasurement(
    String petId,
    String measurementId,
  ) async {
    if (failDelete) {
      throw StateError('Health measurement deletion failed');
    }

    records.removeWhere(
      (record) =>
          record.petId == petId && record.measurementId == measurementId,
    );
  }
}

// =============================================================================
// Test harness
// =============================================================================

class _HealthControllerHarness {
  final medicalConditionRepository = _FakeMedicalConditionRepository();
  final vaccinationRepository = _FakeVaccinationRepository();
  final treatmentRepository = _FakeTreatmentRepository();
  final healthMeasurementRepository = _FakeHealthMeasurementRepository();

  late final HealthController controller = HealthController(
    createMedicalCondition: CreateMedicalCondition(medicalConditionRepository),
    getMedicalConditions: GetMedicalConditions(medicalConditionRepository),
    updateMedicalCondition: UpdateMedicalCondition(medicalConditionRepository),
    deleteMedicalCondition: DeleteMedicalCondition(medicalConditionRepository),
    createVaccination: CreateVaccination(vaccinationRepository),
    getVaccinations: GetVaccinations(vaccinationRepository),
    updateVaccination: UpdateVaccination(vaccinationRepository),
    deleteVaccination: DeleteVaccination(vaccinationRepository),
    createTreatment: CreateTreatment(treatmentRepository),
    getTreatments: GetTreatments(treatmentRepository),
    updateTreatment: UpdateTreatment(treatmentRepository),
    deleteTreatment: DeleteTreatment(treatmentRepository),
    createHealthMeasurement: CreateHealthMeasurement(
      healthMeasurementRepository,
    ),
    getHealthMeasurements: GetHealthMeasurements(healthMeasurementRepository),
    updateHealthMeasurement: UpdateHealthMeasurement(
      healthMeasurementRepository,
    ),
    deleteHealthMeasurement: DeleteHealthMeasurement(
      healthMeasurementRepository,
    ),
  );

  void seedRecords({
    List<MedicalCondition> medicalConditions = const [],
    List<Vaccination> vaccinations = const [],
    List<Treatment> treatments = const [],
    List<HealthMeasurement> healthMeasurements = const [],
  }) {
    medicalConditionRepository.records = List.of(medicalConditions);
    vaccinationRepository.records = List.of(vaccinations);
    treatmentRepository.records = List.of(treatments);
    healthMeasurementRepository.records = List.of(healthMeasurements);
  }

  void dispose() {
    controller.dispose();
  }
}

// =============================================================================
// Test fixtures
// =============================================================================

DateTime _date(int day) => DateTime(2026, 10, day);

MedicalCondition _condition({
  String id = 'condition-1',
  String petId = 'pet-1',
  String name = 'Skin condition',
  String status = 'active',
  String source = 'owner',
}) {
  return MedicalCondition(
    conditionId: id,
    petId: petId,
    name: name,
    status: status,
    source: source,
    diagnosisDate: _date(1),
    notes: '',
    createdAt: _date(1),
    updatedAt: _date(1),
  );
}

Vaccination _vaccination({
  String id = 'vaccination-1',
  String petId = 'pet-1',
  String name = 'Rabies vaccine',
  DateTime? dateGiven,
  DateTime? nextDueDate,
}) {
  return Vaccination(
    vaccinationId: id,
    petId: petId,
    name: name,
    dateGiven: dateGiven ?? _date(2),
    nextDueDate: nextDueDate,
    notes: '',
    createdAt: _date(2),
    updatedAt: _date(2),
  );
}

Treatment _treatment({
  String id = 'treatment-1',
  String petId = 'pet-1',
  String name = 'Medication',
  String status = 'active',
  String source = 'owner',
}) {
  return Treatment(
    treatmentId: id,
    petId: petId,
    name: name,
    status: status,
    source: source,
    startDate: _date(3),
    notes: '',
    createdAt: _date(3),
    updatedAt: _date(3),
  );
}

HealthMeasurement _measurement({
  String id = 'measurement-1',
  String petId = 'pet-1',
  String type = 'weight',
  double value = 12.5,
  String unit = 'kg',
  DateTime? recordedAt,
}) {
  return HealthMeasurement(
    measurementId: id,
    petId: petId,
    type: type,
    value: value,
    unit: unit,
    recordedAt: recordedAt ?? _date(4),
    createdAt: _date(4),
    updatedAt: _date(4),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('HealthController', () {
    // -------------------------------------------------------------------------
    // Load health records
    // -------------------------------------------------------------------------

    group('loadHealthRecords', () {
      test('loads all four health record collections', () async {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        final condition = _condition();
        final vaccination = _vaccination();
        final treatment = _treatment();
        final measurement = _measurement();

        harness.seedRecords(
          medicalConditions: [condition],
          vaccinations: [vaccination],
          treatments: [treatment],
          healthMeasurements: [measurement],
        );

        final loadingStates = <bool>[];

        harness.controller.addListener(() {
          loadingStates.add(harness.controller.isLoading);
        });

        await harness.controller.loadHealthRecords('pet-1');

        expect(harness.controller.medicalConditions, [condition]);
        expect(harness.controller.vaccinations, [vaccination]);
        expect(harness.controller.treatments, [treatment]);
        expect(harness.controller.healthMeasurements, [measurement]);

        expect(harness.controller.isLoading, isFalse);
        expect(harness.controller.errorMessage, isNull);
        expect(loadingStates, [true, false]);
      });

      test('reports an error when loading records fails', () async {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        harness.medicalConditionRepository.failRead = true;

        await harness.controller.loadHealthRecords('pet-1');

        expect(harness.controller.isLoading, isFalse);
        expect(
          harness.controller.errorMessage,
          'Unable to complete the health operation.',
        );
      });
    });

    // -------------------------------------------------------------------------
    // Create health records
    // -------------------------------------------------------------------------

    group('create operations', () {
      test('creates all four types of health records', () async {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        final condition = _condition();
        final vaccination = _vaccination();
        final treatment = _treatment();
        final measurement = _measurement();

        expect(
          await harness.controller.createMedicalCondition(condition),
          isTrue,
        );

        expect(await harness.controller.createVaccination(vaccination), isTrue);

        expect(await harness.controller.createTreatment(treatment), isTrue);

        expect(
          await harness.controller.createHealthMeasurement(measurement),
          isTrue,
        );

        expect(harness.controller.medicalConditions, [condition]);
        expect(harness.controller.vaccinations, [vaccination]);
        expect(harness.controller.treatments, [treatment]);
        expect(harness.controller.healthMeasurements, [measurement]);

        expect(harness.controller.isLoading, isFalse);
        expect(harness.controller.errorMessage, isNull);
      });

      test('returns false and reports an error when creation fails', () async {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        harness.medicalConditionRepository.failCreate = true;

        final result = await harness.controller.createMedicalCondition(
          _condition(),
        );

        expect(result, isFalse);
        expect(harness.controller.medicalConditions, isEmpty);
        expect(harness.controller.isLoading, isFalse);
        expect(
          harness.controller.errorMessage,
          'Unable to complete the health operation.',
        );
      });
    });

    // -------------------------------------------------------------------------
    // Update health records
    // -------------------------------------------------------------------------

    group('update operations', () {
      test('updates records in all four collections', () async {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        harness.seedRecords(
          medicalConditions: [_condition()],
          vaccinations: [_vaccination()],
          treatments: [_treatment()],
          healthMeasurements: [_measurement()],
        );

        await harness.controller.loadHealthRecords('pet-1');

        final updatedCondition = _condition(name: 'Updated skin condition');

        final updatedVaccination = _vaccination(name: 'Updated rabies vaccine');

        final updatedTreatment = _treatment(name: 'Updated medication');

        final updatedMeasurement = _measurement(value: 13.0);

        expect(
          await harness.controller.updateMedicalCondition(updatedCondition),
          isTrue,
        );

        expect(
          await harness.controller.updateVaccination(updatedVaccination),
          isTrue,
        );

        expect(
          await harness.controller.updateTreatment(updatedTreatment),
          isTrue,
        );

        expect(
          await harness.controller.updateHealthMeasurement(updatedMeasurement),
          isTrue,
        );

        expect(
          harness.controller.medicalConditions.first.name,
          'Updated skin condition',
        );

        expect(
          harness.controller.vaccinations.first.name,
          'Updated rabies vaccine',
        );

        expect(harness.controller.treatments.first.name, 'Updated medication');

        expect(harness.controller.healthMeasurements.first.value, 13.0);

        expect(harness.controller.errorMessage, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // Delete health records
    // -------------------------------------------------------------------------

    group('delete operations', () {
      test('deletes records from all four collections', () async {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        harness.seedRecords(
          medicalConditions: [_condition()],
          vaccinations: [_vaccination()],
          treatments: [_treatment()],
          healthMeasurements: [_measurement()],
        );

        await harness.controller.loadHealthRecords('pet-1');

        expect(
          await harness.controller.deleteMedicalCondition(
            'pet-1',
            'condition-1',
          ),
          isTrue,
        );

        expect(
          await harness.controller.deleteVaccination('pet-1', 'vaccination-1'),
          isTrue,
        );

        expect(
          await harness.controller.deleteTreatment('pet-1', 'treatment-1'),
          isTrue,
        );

        expect(
          await harness.controller.deleteHealthMeasurement(
            'pet-1',
            'measurement-1',
          ),
          isTrue,
        );

        expect(harness.controller.medicalConditions, isEmpty);
        expect(harness.controller.vaccinations, isEmpty);
        expect(harness.controller.treatments, isEmpty);
        expect(harness.controller.healthMeasurements, isEmpty);

        expect(harness.controller.errorMessage, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // Loading state
    // -------------------------------------------------------------------------

    group('loading state', () {
      test('rejects another operation while one is in progress', () async {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        final condition = _condition();
        final completer = Completer<MedicalCondition>();

        harness.medicalConditionRepository.createGate = completer;

        final firstOperation = harness.controller.createMedicalCondition(
          condition,
        );

        expect(harness.controller.isLoading, isTrue);

        final secondResult = await harness.controller.createMedicalCondition(
          condition,
        );

        expect(secondResult, isFalse);

        completer.complete(condition);

        final firstResult = await firstOperation;

        expect(firstResult, isTrue);
        expect(harness.controller.isLoading, isFalse);
        expect(harness.controller.medicalConditions, [condition]);
      });
    });

    // -------------------------------------------------------------------------
    // Error handling
    // -------------------------------------------------------------------------

    group('error handling', () {
      test('clearError removes the current error message', () async {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        harness.medicalConditionRepository.failCreate = true;

        await harness.controller.createMedicalCondition(_condition());

        expect(harness.controller.errorMessage, isNotNull);

        harness.controller.clearError();

        expect(harness.controller.errorMessage, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // Collection safety
    // -------------------------------------------------------------------------

    group('record collection getters', () {
      test('returns unmodifiable record collections', () {
        final harness = _HealthControllerHarness();
        addTearDown(harness.dispose);

        expect(
          () => harness.controller.medicalConditions.add(_condition()),
          throwsUnsupportedError,
        );

        expect(
          () => harness.controller.vaccinations.add(_vaccination()),
          throwsUnsupportedError,
        );

        expect(
          () => harness.controller.treatments.add(_treatment()),
          throwsUnsupportedError,
        );

        expect(
          () => harness.controller.healthMeasurements.add(_measurement()),
          throwsUnsupportedError,
        );
      });
    });
  });
}
