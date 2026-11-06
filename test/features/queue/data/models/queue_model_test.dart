import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/queue/data/models/queue_model.dart';
import 'package:petcare/features/queue/domain/entities/queue.dart'
    as queue_entity;
import 'package:petcare/features/queue/domain/entities/queue_status.dart';

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
  String veterinarianId = '',
  String queueSequence = '',
  DateTime? createdAt,
  DateTime? calledAt,
  DateTime? consultationStartedAt,
  DateTime? completedAt,
  DateTime? skippedAt,
  DateTime? cancelledAt,
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
    veterinarianId: veterinarianId,
    queueSequence: queueSequence,
    createdAt: createdAt,
    calledAt: calledAt,
    consultationStartedAt: consultationStartedAt,
    completedAt: completedAt,
    skippedAt: skippedAt,
    cancelledAt: cancelledAt,
  );
}

/// Represents a valid queue record stored in Firestore.
///
/// A fresh map is returned for every test so mutations remain isolated.
Map<String, dynamic> _queueMap({bool includeExtensions = false}) {
  final map = <String, dynamic>{
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

  if (includeExtensions) {
    map.addAll({
      'veterinarianId': 'vet-001',
      'queueSequence': 'A003',
      'createdAt': '2026-11-03T09:00:00.000Z',
      'calledAt': '2026-11-03T10:00:00.000Z',
      'consultationStartedAt': '2026-11-03T10:05:00.000Z',
      'completedAt': '2026-11-03T10:30:00.000Z',
      'skippedAt': '2026-11-03T10:40:00.000Z',
      'cancelledAt': '2026-11-03T10:50:00.000Z',
    });
  }

  return map;
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

    test('deserializes extended lifecycle metadata', () {
      final map = _queueMap(includeExtensions: true)
        ..['status'] = 'called'
        ..['createdAt'] = Timestamp.fromDate(DateTime.utc(2026, 11, 3, 9));

      final model = QueueModel.fromMap(map);

      expect(model.veterinarianId, 'vet-001');
      expect(model.queueSequence, 'A003');
      expect(model.createdAt?.toUtc(), DateTime.utc(2026, 11, 3, 9));
      expect(model.calledAt, DateTime.utc(2026, 11, 3, 10));
      expect(model.consultationStartedAt, DateTime.utc(2026, 11, 3, 10, 5));
      expect(model.completedAt, DateTime.utc(2026, 11, 3, 10, 30));
      expect(model.skippedAt, DateTime.utc(2026, 11, 3, 10, 40));
      expect(model.cancelledAt, DateTime.utc(2026, 11, 3, 10, 50));
      expect(model.queueStatus, QueueStatus.called);
      expect(model.isTerminal, isFalse);
      expect(model.hasAssignedVeterinarian, isTrue);
    });

    test('defaults optional lifecycle metadata for legacy records', () {
      final model = QueueModel.fromMap(_queueMap());

      expect(model.veterinarianId, isEmpty);
      expect(model.queueSequence, isEmpty);
      expect(model.createdAt, isNull);
      expect(model.calledAt, isNull);
      expect(model.consultationStartedAt, isNull);
      expect(model.completedAt, isNull);
      expect(model.skippedAt, isNull);
      expect(model.cancelledAt, isNull);
      expect(model.hasAssignedVeterinarian, isFalse);
    });

    test('parses terminal lifecycle states', () {
      for (final status in ['completed', 'skipped', 'cancelled']) {
        final model = QueueModel.fromMap(_queueMap()..['status'] = status);

        expect(model.queueStatus, QueueStatus.fromValue(status));
        expect(model.isTerminal, isTrue);
      }
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

    test('rejects malformed optional relationship fields', () {
      for (final field in ['veterinarianId', 'queueSequence']) {
        final map = _queueMap()..[field] = 123;

        expect(
          () => QueueModel.fromMap(map),
          throwsA(isA<FormatException>()),
          reason: 'Malformed optional field "$field" must be rejected.',
        );
      }
    });

    test('rejects malformed optional timestamps', () {
      for (final field in [
        'createdAt',
        'calledAt',
        'consultationStartedAt',
        'completedAt',
        'skippedAt',
        'cancelledAt',
      ]) {
        final map = _queueMap()..[field] = 'not-a-date';

        expect(
          () => QueueModel.fromMap(map),
          throwsA(isA<FormatException>()),
          reason: 'Malformed timestamp "$field" must be rejected.',
        );
      }
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

    test('serializes extended lifecycle metadata', () {
      final model = _queueModel(
        veterinarianId: 'vet-001',
        queueSequence: 'A003',
        createdAt: DateTime.utc(2026, 11, 3, 9),
        calledAt: DateTime.utc(2026, 11, 3, 10),
        consultationStartedAt: DateTime.utc(2026, 11, 3, 10, 5),
        completedAt: DateTime.utc(2026, 11, 3, 10, 30),
        skippedAt: DateTime.utc(2026, 11, 3, 10, 40),
        cancelledAt: DateTime.utc(2026, 11, 3, 10, 50),
      );

      final map = model.toMap();

      expect(map['veterinarianId'], 'vet-001');
      expect(map['queueSequence'], 'A003');
      expect(map['createdAt'], '2026-11-03T09:00:00.000Z');
      expect(map['calledAt'], '2026-11-03T10:00:00.000Z');
      expect(map['consultationStartedAt'], '2026-11-03T10:05:00.000Z');
      expect(map['completedAt'], '2026-11-03T10:30:00.000Z');
      expect(map['skippedAt'], '2026-11-03T10:40:00.000Z');
      expect(map['cancelledAt'], '2026-11-03T10:50:00.000Z');
    });

    test('omits optional metadata when it is not populated', () {
      final map = _queueModel().toMap();

      for (final field in [
        'veterinarianId',
        'queueSequence',
        'createdAt',
        'calledAt',
        'consultationStartedAt',
        'completedAt',
        'skippedAt',
        'cancelledAt',
      ]) {
        expect(map, isNot(contains(field)));
      }
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
        veterinarianId: 'vet-002',
        queueSequence: 'A004',
        createdAt: DateTime.utc(2026, 11, 3, 9),
        calledAt: DateTime.utc(2026, 11, 3, 10),
        consultationStartedAt: DateTime.utc(2026, 11, 3, 10, 5),
        completedAt: DateTime.utc(2026, 11, 3, 10, 30),
        skippedAt: DateTime.utc(2026, 11, 3, 10, 40),
        cancelledAt: DateTime.utc(2026, 11, 3, 10, 50),
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
      expect(model.veterinarianId, entity.veterinarianId);
      expect(model.queueSequence, entity.queueSequence);
      expect(model.createdAt, entity.createdAt);
      expect(model.calledAt, entity.calledAt);
      expect(model.consultationStartedAt, entity.consultationStartedAt);
      expect(model.completedAt, entity.completedAt);
      expect(model.skippedAt, entity.skippedAt);
      expect(model.cancelledAt, entity.cancelledAt);

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

    test('preserves extended lifecycle metadata', () {
      final original = _queueModel(
        status: 'cancelled',
        veterinarianId: 'vet-001',
        queueSequence: 'A003',
        createdAt: DateTime.utc(2026, 11, 3, 9),
        cancelledAt: DateTime.utc(2026, 11, 3, 10, 50),
      );

      final restored = QueueModel.fromMap(original.toMap());

      expect(restored.veterinarianId, original.veterinarianId);
      expect(restored.queueSequence, original.queueSequence);
      expect(restored.createdAt, original.createdAt);
      expect(restored.cancelledAt, original.cancelledAt);
      expect(restored.queueStatus, QueueStatus.cancelled);
      expect(restored.isTerminal, isTrue);
    });
  });
}
