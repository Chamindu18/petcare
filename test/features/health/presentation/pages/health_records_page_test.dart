import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
import 'package:petcare/features/health/presentation/pages/health_records_page.dart';
import 'package:petcare/features/health/presentation/providers/health_controller.dart';
import 'package:petcare/features/pets/domain/entities/pet.dart';

class _Conditions extends Fake implements MedicalConditionRepository {
  final records = <MedicalCondition>[];
  final requests = <String>[];
  final pending = <String, Completer<List<MedicalCondition>>>{};
  bool fail = false;
  Object? readError;

  @override
  Future<List<MedicalCondition>> getMedicalConditions(String petId) {
    requests.add(petId);
    if (readError != null) return Future.error(readError!);
    if (fail) return Future.error(StateError('network unavailable'));
    final gate = pending[petId];
    if (gate != null) return gate.future;
    return Future.value(records.where((r) => r.petId == petId).toList());
  }
}

class _Vaccinations extends Fake implements VaccinationRepository {
  @override
  Future<List<Vaccination>> getVaccinations(String petId) async => [];
}

class _Treatments extends Fake implements TreatmentRepository {
  @override
  Future<List<Treatment>> getTreatments(String petId) async => [];
}

class _Measurements extends Fake implements HealthMeasurementRepository {
  @override
  Future<List<HealthMeasurement>> getHealthMeasurements(String petId) async =>
      [];
}

class _Harness {
  final conditions = _Conditions();
  final vaccinations = _Vaccinations();
  final treatments = _Treatments();
  final measurements = _Measurements();

  late final controller = HealthController(
    createMedicalCondition: CreateMedicalCondition(conditions),
    getMedicalConditions: GetMedicalConditions(conditions),
    updateMedicalCondition: UpdateMedicalCondition(conditions),
    deleteMedicalCondition: DeleteMedicalCondition(conditions),
    createVaccination: CreateVaccination(vaccinations),
    getVaccinations: GetVaccinations(vaccinations),
    updateVaccination: UpdateVaccination(vaccinations),
    deleteVaccination: DeleteVaccination(vaccinations),
    createTreatment: CreateTreatment(treatments),
    getTreatments: GetTreatments(treatments),
    updateTreatment: UpdateTreatment(treatments),
    deleteTreatment: DeleteTreatment(treatments),
    createHealthMeasurement: CreateHealthMeasurement(measurements),
    getHealthMeasurements: GetHealthMeasurements(measurements),
    updateHealthMeasurement: UpdateHealthMeasurement(measurements),
    deleteHealthMeasurement: DeleteHealthMeasurement(measurements),
  );
}

Pet _pet(String id) => Pet(
  petId: id,
  ownerId: 'owner',
  name: id,
  species: 'Dog',
  breed: 'Mixed',
  dob: DateTime(2020),
  gender: 'Male',
  weight: 10,
  imageUrl: '',
  notes: '',
  status: 'active',
);

MedicalCondition _condition(String petId) => MedicalCondition(
  conditionId: 'condition-$petId',
  petId: petId,
  name: 'Allergy',
  status: 'active',
  source: 'owner_reported',
  diagnosisDate: DateTime(2024),
  notes: '',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Future<void> _show(WidgetTester tester, _Harness harness, String petId) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HealthRecordsPage(pet: _pet(petId), controller: harness.controller),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('successful populated load shows actual counts', (tester) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    harness.conditions.records.add(_condition('pet-a'));

    await _show(tester, harness, 'pet-a');

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(harness.controller.loadedPetId, 'pet-a');
  });

  testWidgets('successful empty load permits genuine zero counts', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);

    await _show(tester, harness, 'pet-a');

    expect(find.text('0'), findsNWidgets(4));
    expect(harness.controller.errorMessage, isNull);
  });

  testWidgets('loading hides summary counts', (tester) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    final gate = Completer<List<MedicalCondition>>();
    harness.conditions.pending['pet-a'] = gate;

    await tester.pumpWidget(
      MaterialApp(
        home: HealthRecordsPage(
          pet: _pet('pet-a'),
          controller: harness.controller,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('0'), findsNothing);
    gate.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNWidgets(4));
  });

  testWidgets('failed load shows an error without false zero counts', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    harness.conditions.records.add(_condition('pet-a'));
    harness.conditions.fail = true;

    await _show(tester, harness, 'pet-a');

    expect(
      find.text('Unable to complete the health operation.'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNothing);
  });

  testWidgets('permission denied shows a safe error without zero counts', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    harness.conditions.readError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'private backend detail',
    );

    await _show(tester, harness, 'pet-a');

    expect(
      find.text('Unable to complete the health operation.'),
      findsOneWidget,
    );
    expect(find.textContaining('private backend detail'), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets(
    'retry restores counts and repeated retry taps do not duplicate reads',
    (tester) async {
      final harness = _Harness();
      addTearDown(harness.controller.dispose);
      harness.conditions.records.add(_condition('pet-a'));
      harness.conditions.fail = true;
      await _show(tester, harness, 'pet-a');
      harness.conditions.fail = false;
      final gate = Completer<List<MedicalCondition>>();
      harness.conditions.pending['pet-a'] = gate;

      await tester.tap(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(harness.conditions.requests, ['pet-a', 'pet-a']);
      expect(find.text('0'), findsNothing);

      gate.complete([_condition('pet-a')]);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    },
  );

  testWidgets('pet switch ignores late previous response', (tester) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    final oldGate = Completer<List<MedicalCondition>>();
    final newGate = Completer<List<MedicalCondition>>();
    harness.conditions.pending['pet-a'] = oldGate;
    harness.conditions.pending['pet-b'] = newGate;

    await tester.pumpWidget(
      MaterialApp(
        home: HealthRecordsPage(
          pet: _pet('pet-a'),
          controller: harness.controller,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: HealthRecordsPage(
          pet: _pet('pet-b'),
          controller: harness.controller,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0'), findsNothing);

    oldGate.complete([_condition('pet-a')]);
    await tester.pump();
    expect(find.text('Allergy'), findsNothing);
    expect(find.text('0'), findsNothing);

    newGate.complete([]);
    await tester.pumpAndSettle();
    expect(harness.controller.loadedPetId, 'pet-b');
    expect(harness.controller.medicalConditions, isEmpty);
    expect(find.text('0'), findsNWidgets(4));
  });

  testWidgets('health analytics navigation uses successfully loaded data', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    harness.conditions.records.add(_condition('pet-a'));
    await _show(tester, harness, 'pet-a');

    await tester.tap(find.text('View Health Analytics'));
    await tester.pumpAndSettle();

    expect(find.text('Health Analytics'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('health analytics failure does not show false counts', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    harness.conditions.records.add(_condition('pet-a'));
    harness.conditions.fail = true;
    await _show(tester, harness, 'pet-a');

    await tester.tap(find.text('View Health Analytics'));
    await tester.pumpAndSettle();

    expect(find.text('Health Analytics'), findsOneWidget);
    expect(
      find.text('Unable to complete the health operation.'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNothing);
  });
}
