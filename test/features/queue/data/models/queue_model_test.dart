import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/queue/data/models/queue_model.dart';
import 'package:petcare/features/queue/domain/entities/queue.dart'
    as queue_entity;

/// Creates a valid queue model unless an individual value is overridden.
QueueModel _queueModel({
  String queueId = 'queue-001',
  String appointmentId = 'appointment-001',
  String hospitalId = 'hospital-001',
  String ownerId = 'owner-001',
  String petId = 'pet-001',
  int queueNumber = 3,
  int currentServing = 1,
  int position = 2,
  String status = 'waiting',
  DateTime? updatedAt,
}) {
  return QueueModel(
    queueId: queueId,
    appointmentId: appointmentId,
    hospitalId: hospitalId,
    ownerId: ownerId,
    petId: petId,
    queueNumber: queueNumber,
    currentServing: currentServing,
    position: position,
    status: status,
    updatedAt: updatedAt ?? DateTime.utc(2026, 11, 3, 10),
  );
}

/// Represents a valid queue record stored in Firestore.
///
/// A fresh map is returned for every test so mutations remain isolated.
Map<String, dynamic> _queueMap() {
  return {
    'queueId': 'queue-001',
    'appointmentId': 'appointment-001',
    'hospitalId': 'hospital-001',
    'ownerId': 'owner-001',
    'petId': 'pet-001',
    'queueNumber': 3,
    'currentServing': 1,
    'position': 2,
    'status': 'waiting',
    'updatedAt': '2026-11-03T10:00:00.000Z',
  };
}

void main() {
  group('QueueModel.fromMap', () {
    test('deserializes a valid Firestore queue record', () {
      final model = QueueModel.fromMap(_queueMap());

      expect(model.queueId, 'queue-001');
      expect(model.appointmentId, 'appointment-001');
      expect(model.hospitalId, 'hospital-001');
      expect(model.ownerId, 'owner-001');
      expect(model.petId, 'pet-001');

      expect(model.queueNumber, 3);
      expect(model.currentServing, 1);
      expect(model.position, 2);
      expect(model.status, 'waiting');

      expect(model.updatedAt, DateTime.utc(2026, 11, 3, 10));

      expect(model.hasValidRelationships, isTrue);
      expect(model.hasValidQueueNumbers, isTrue);
    });

    test('preserves readability of legacy records', () {
      final legacyMap = _queueMap()
        ..remove('hospitalId')
        ..remove('ownerId')
        ..remove('petId');

      final model = QueueModel.fromMap(legacyMap);

      expect(model.queueId, 'queue-001');
      expect(model.appointmentId, 'appointment-001');

      expect(model.hospitalId, isEmpty);
      expect(model.ownerId, isEmpty);
      expect(model.petId, isEmpty);

      expect(model.hasValidRelationships, isFalse);
    });

    test('rejects a malformed relationship field', () {
      final map = _queueMap();
      map['hospitalId'] = 123;

      expect(() => QueueModel.fromMap(map), throwsA(isA<FormatException>()));
    });

    test('rejects a malformed queue number', () {
      final map = _queueMap();
      map['queueNumber'] = 'three';

      expect(() => QueueModel.fromMap(map), throwsA(isA<TypeError>()));
    });

    test('rejects an invalid date format', () {
      final map = _queueMap();
      map['updatedAt'] = 'not-a-date';

      expect(() => QueueModel.fromMap(map), throwsA(isA<FormatException>()));
    });

    test('rejects a missing required appointment ID', () {
      final map = _queueMap()..remove('appointmentId');

      expect(() => QueueModel.fromMap(map), throwsA(isA<TypeError>()));
    });
  });

  group('QueueModel.toMap', () {
    test('serializes every required queue field', () {
      final model = _queueModel();

      final map = model.toMap();

      expect(map['queueId'], 'queue-001');
      expect(map['appointmentId'], 'appointment-001');
      expect(map['hospitalId'], 'hospital-001');
      expect(map['ownerId'], 'owner-001');
      expect(map['petId'], 'pet-001');

      expect(map['queueNumber'], 3);
      expect(map['currentServing'], 1);
      expect(map['position'], 2);
      expect(map['status'], 'waiting');

      expect(map['updatedAt'], DateTime.utc(2026, 11, 3, 10).toIso8601String());
    });

    test('converts local timestamps to UTC for persistence', () {
      final localDate = DateTime(2026, 11, 3, 15, 30);

      final model = _queueModel(updatedAt: localDate);

      final map = model.toMap();
      final serializedDate = DateTime.parse(map['updatedAt'] as String);

      expect(serializedDate.isUtc, isTrue);
      expect(serializedDate.isAtSameMomentAs(localDate), isTrue);
    });

    test('rejects missing hospital relationships', () {
      final model = _queueModel(hospitalId: '');

      expect(model.hasValidRelationships, isFalse);

      expect(model.toMap, throwsA(isA<StateError>()));
    });

    test('rejects missing owner and pet relationships', () {
      for (final model in [_queueModel(ownerId: ' '), _queueModel(petId: '')]) {
        expect(model.hasValidRelationships, isFalse);

        expect(model.toMap, throwsA(isA<StateError>()));
      }
    });

    test('rejects invalid queue numbers', () {
      for (final model in [
        _queueModel(queueNumber: 0),
        _queueModel(queueNumber: -1),
        _queueModel(currentServing: -1),
        _queueModel(position: -1),
      ]) {
        expect(model.hasValidQueueNumbers, isFalse);

        expect(model.toMap, throwsA(isA<StateError>()));
      }
    });

    test('accepts a zero position for the currently served patient', () {
      final model = _queueModel(
        currentServing: 3,
        position: 0,
        status: 'in_consultation',
      );

      expect(model.hasValidQueueNumbers, isTrue);

      final map = model.toMap();

      expect(map['position'], 0);
      expect(map['status'], 'in_consultation');
    });

    test('rejects an empty queue status', () {
      final model = _queueModel(status: '  ');

      expect(model.toMap, throwsA(isA<StateError>()));
    });

    test('rejects serialization of a legacy record', () {
      final legacyMap = _queueMap()
        ..remove('hospitalId')
        ..remove('ownerId')
        ..remove('petId');

      final model = QueueModel.fromMap(legacyMap);

      expect(model.toMap, throwsA(isA<StateError>()));
    });
  });

  group('QueueModel.fromEntity', () {
    test('preserves all fields from a domain queue entity', () {
      final entity = queue_entity.Queue(
        queueId: 'queue-002',
        appointmentId: 'appointment-002',
        hospitalId: 'hospital-001',
        ownerId: 'owner-002',
        petId: 'pet-002',
        queueNumber: 4,
        currentServing: 2,
        position: 2,
        status: 'waiting',
        updatedAt: DateTime.utc(2026, 11, 3, 11),
      );

      final model = QueueModel.fromEntity(entity);

      expect(model.queueId, entity.queueId);
      expect(model.appointmentId, entity.appointmentId);
      expect(model.hospitalId, entity.hospitalId);
      expect(model.ownerId, entity.ownerId);
      expect(model.petId, entity.petId);
      expect(model.queueNumber, entity.queueNumber);
      expect(model.currentServing, entity.currentServing);
      expect(model.position, entity.position);
      expect(model.status, entity.status);
      expect(model.updatedAt, entity.updatedAt);

      expect(model.hasValidRelationships, isTrue);
    });
  });

  group('QueueModel round-trip serialization', () {
    test('preserves identity and operational state', () {
      final original = _queueModel(
        queueId: 'queue-roundtrip',
        appointmentId: 'appointment-roundtrip',
        queueNumber: 7,
        currentServing: 5,
        position: 2,
        status: 'waiting',
      );

      final restored = QueueModel.fromMap(original.toMap());

      expect(restored.queueId, original.queueId);
      expect(restored.appointmentId, original.appointmentId);

      expect(restored.hospitalId, original.hospitalId);
      expect(restored.ownerId, original.ownerId);
      expect(restored.petId, original.petId);

      expect(restored.queueNumber, original.queueNumber);
      expect(restored.currentServing, original.currentServing);
      expect(restored.position, original.position);
      expect(restored.status, original.status);

      expect(restored.updatedAt.isAtSameMomentAs(original.updatedAt), isTrue);
    });
  });
}
