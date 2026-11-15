import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/ai_assistant/presentation/pages/ai_hub_page.dart';
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
import 'package:petcare/features/pets/domain/entities/pet.dart';

class _ConditionsRepository implements MedicalConditionRepository {
  final Map<String, Completer<List<MedicalCondition>>> pending = {};
  final Map<String, List<MedicalCondition>> records = {};

  @override
  Future<List<MedicalCondition>> getMedicalConditions(String petId) =>
      pending[petId]?.future ?? Future.value(records[petId] ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VaccinationsRepository implements VaccinationRepository {
  @override
  Future<List<Vaccination>> getVaccinations(String petId) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TreatmentsRepository implements TreatmentRepository {
  @override
  Future<List<Treatment>> getTreatments(String petId) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MeasurementsRepository implements HealthMeasurementRepository {
  @override
  Future<List<HealthMeasurement>> getHealthMeasurements(String petId) async =>
      [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HealthController _controller(_ConditionsRepository conditions) {
  final vaccinations = _VaccinationsRepository();
  final treatments = _TreatmentsRepository();
  final measurements = _MeasurementsRepository();
  return HealthController(
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
  name: 'Pet $id',
  species: 'Dog',
  breed: 'Mixed',
  dob: DateTime(2020),
  gender: 'female',
  weight: 10,
  imageUrl: '',
  notes: '',
  status: 'active',
);

MedicalCondition _condition(String petId) => MedicalCondition(
  conditionId: '$petId-condition',
  petId: petId,
  name: '$petId allergy',
  status: 'active',
  source: 'owner',
  diagnosisDate: DateTime(2024),
  notes: '',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Future<void> _select(WidgetTester tester, String id) async {
  await tester.tap(find.byType(DropdownButton<Pet>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pet $id').last);
  await tester.pump();
}

Future<void> _openSummary(WidgetTester tester) async {
  await tester.tap(find.text('Health Summary').first);
  await tester.pumpAndSettle();
}

void main() {
  late _ConditionsRepository conditions;
  late HealthController controller;

  setUp(() {
    conditions = _ConditionsRepository();
    controller = _controller(conditions);
  });
  tearDown(() => controller.dispose());

  Future<void> showHub(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AIHubPage(
          pets: [_pet('A'), _pet('B')],
          healthController: controller,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('normal selection shows only the selected pet records', (
    tester,
  ) async {
    conditions.records['A'] = [_condition('A')];
    conditions.records['B'] = [];
    await showHub(tester);
    expect(controller.loadedPetId, 'A');
    await _openSummary(tester);
    expect(find.text('Pet A'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('General Care Guidance'), findsOneWidget);
    expect(find.text('AI Recommendation'), findsNothing);
    expect(
      find.textContaining("Continue monitoring your pet's health"),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _select(tester, 'B');
    await tester.pump();
    expect(controller.loadedPetId, 'B');
    expect(controller.medicalConditions, isEmpty);
    await _openSummary(tester);
    expect(find.text('Pet B'), findsWidgets);
    expect(find.text('0'), findsNWidgets(4));
    expect(find.text('General Care Guidance'), findsOneWidget);
    expect(find.text('Pet A'), findsNothing);
  });

  testWidgets('rapid switching ignores late Pet A results', (tester) async {
    final pendingA = Completer<List<MedicalCondition>>();
    conditions.pending['A'] = pendingA;
    conditions.records['B'] = [_condition('B')];
    await showHub(tester);
    await _select(tester, 'B');
    await tester.pump();
    expect(controller.loadedPetId, 'B');
    pendingA.complete([_condition('A')]);
    await tester.pump();
    expect(controller.loadedPetId, 'B');
    expect(controller.medicalConditions.single.petId, 'B');
    await _openSummary(tester);
    expect(find.text('Pet B'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Pet A'), findsNothing);
  });

  testWidgets('failed Pet B load does not use Pet A records', (tester) async {
    conditions.records['A'] = [_condition('A')];
    final pendingB = Completer<List<MedicalCondition>>();
    conditions.pending['B'] = pendingB;
    await showHub(tester);
    expect(controller.loadedPetId, 'A');
    await _select(tester, 'B');
    expect(controller.medicalConditions, isEmpty);
    pendingB.completeError(StateError('load failed'));
    await tester.pump();
    expect(controller.loadedPetId, isNull);
    expect(controller.medicalConditions, isEmpty);
    await tester.tap(find.text('Health Summary').first);
    await tester.pump();
    expect(find.text('Please select a pet first.'), findsOneWidget);
    expect(find.text('General Care Guidance'), findsNothing);
  });

  testWidgets('empty records produce an empty-state guidance response', (
    tester,
  ) async {
    await showHub(tester);
    await tester.pump();
    expect(controller.loadedPetId, 'A');
    await tester.tap(find.text('Ask me anything...'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'conditions');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      find.text('PET A HAS NO RECORDED MEDICAL CONDITIONS.'),
      findsOneWidget,
    );
  });
}
