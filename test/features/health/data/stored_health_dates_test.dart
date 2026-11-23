import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/health/data/models/health_measurement_model.dart';
import 'package:petcare/features/health/data/models/medical_condition_model.dart';
import 'package:petcare/features/health/data/models/treatment_model.dart';
import 'package:petcare/features/health/data/repositories/firebase_vaccination_repository.dart';

void main() {
  const valid = '2024-02-29T01:00:00+05:30';
  const base = {
    'petId': 'pet',
    'name': 'record',
    'notes': '',
    'createdAt': valid,
    'updatedAt': valid,
  };

  test('mixed vaccination history preserves valid dates and omits unreadable records', () async {
    final db = FakeFirebaseFirestore();
    final repository = FirebaseVaccinationRepository(
      firestore: db,
      auth: MockFirebaseAuth(signedIn: true),
    );
    final records = db.collection('vaccinations');
    for (final entry in {
      'valid': valid,
      'bad': '2025-02-29',
      'wrong-type': 42,
      'missing': null,
    }.entries) {
      await records.doc(entry.key).set({
        ...base,
        'vaccinationId': entry.key,
        if (entry.value != null) 'dateGiven': entry.value,
        'nextDueDate': 'unavailable',
      });
    }
    final record = (await repository.getVaccinations('pet')).single;
    expect(record.vaccinationId, 'valid');
    expect(record.dateGiven, DateTime.utc(2024, 2, 28, 19, 30));
    expect(record.nextDueDate, isNull);
    expect(await repository.getVaccinationById('pet', 'bad'), isNull);
  });

  test('condition and measurement require a valid medical date', () {
    final condition = {
      ...base,
      'conditionId': 'c',
      'status': 'active',
      'source': 'owner',
    };
    expect(MedicalConditionModel.tryFromMap(condition), isNull);
    expect(
      MedicalConditionModel.tryFromMap({...condition, 'diagnosisDate': valid}),
      isNotNull,
    );
    final measurement = {
      ...base,
      'measurementId': 'm',
      'type': 'weight',
      'unit': 'kg',
      'value': 4,
    };
    for (final date in ['2026-02-30', '2026-01-01T25:00:00', '', false]) {
      expect(
        HealthMeasurementModel.tryFromMap({...measurement, 'recordedAt': date}),
        isNull,
      );
    }
    expect(
      HealthMeasurementModel.tryFromMap({...measurement, 'recordedAt': valid}),
      isNotNull,
    );
  });

  test(
    'treatment preserves independent optional dates and requires audit dates',
    () {
      final data = {
        ...base,
        'treatmentId': 't',
        'status': 'active',
        'source': 'owner',
        'startDate': 'invalid',
        'endDate': valid,
      };
      final treatment = TreatmentModel.tryFromMap(data)!;
      expect(treatment.startDate, isNull);
      expect(treatment.endDate, DateTime.parse(valid));
      expect(TreatmentModel.tryFromMap({...data, 'updatedAt': null}), isNull);
      expect(
        TreatmentModel.tryFromMap({...data, 'createdAt': 'invalid'}),
        isNull,
      );
    },
  );
}
