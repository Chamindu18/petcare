import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/queue/data/repositories/firebase_queue_repository.dart';
import 'package:petcare/features/queue/domain/repositories/queue_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirebaseQueueRepository repository;
  final today = DateTime.utc(2026, 11, 3, 10);
  Future<void> appointment(
    String id, {
    Map<String, dynamic> patch = const {},
  }) => db.collection('appointments').doc(id).set({
    'appointmentId': id,
    'ownerId': 'owner',
    'petId': 'pet',
    'hospitalId': 'hospital',
    'serviceId': 'service',
    'vetId': 'vet',
    'dateTime': today.toIso8601String(),
    'reason': 'Checkup',
    'status': 'confirmed',
    'createdAt': today.toIso8601String(),
    ...patch,
  });
  setUp(() async {
    db = FakeFirebaseFirestore();
    repository = FirebaseQueueRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'staff'), signedIn: true),
      now: () => today,
    );
    await db.doc('users/staff').set({'role': 'veterinary_staff'});
    await db.doc('hospital_staff/staff').set({
      'userId': 'staff',
      'hospitalId': 'hospital',
      'active': true,
    });
    await appointment('a');
  });

  test(
    'check-in creates linkage, daily ledger and timestamp-readable queue',
    () async {
      final queue = await repository.checkInAppointment(
        appointmentId: 'a',
        hospitalId: 'hospital',
      );
      expect(queue.queueNumber, 1);
      expect(queue.ownerId, 'owner');
      expect(queue.veterinarianId, 'vet');
      expect(queue.createdAt, isNotNull);
      expect(
        (await db.doc('appointments/a').get()).data()!['queueId'],
        queue.queueId,
      );
      expect(
        (await db.doc('hospitals/hospital/queue_days/2026-11-03').get())
            .data()!['lastNumber'],
        1,
      );
      expect(
        (await repository.getQueueByAppointment('a'))!.queueId,
        queue.queueId,
      );
      expect(
        await repository.getHospitalQueue(hospitalId: 'hospital', date: today),
        hasLength(1),
      );
    },
  );

  test('numbers increment and duplicate attempt consumes no number', () async {
    await repository.checkInAppointment(
      appointmentId: 'a',
      hospitalId: 'hospital',
    );
    await expectLater(
      repository.checkInAppointment(appointmentId: 'a', hospitalId: 'hospital'),
      throwsStateError,
    );
    await appointment('b');
    expect(
      (await repository.checkInAppointment(
        appointmentId: 'b',
        hospitalId: 'hospital',
      )).queueNumber,
      2,
    );
  });

  test('wrong hospital, inactive assignment and ineligible appointment leave no writes', () async {
    await expectLater(
      repository.checkInAppointment(appointmentId: 'a', hospitalId: 'other'),
      throwsStateError,
    );
    await db.doc('hospital_staff/staff').update({'active': false});
    await expectLater(
      repository.checkInAppointment(appointmentId: 'a', hospitalId: 'hospital'),
      throwsStateError,
    );
    await db.doc('hospital_staff/staff').update({'active': true});
    for (final patch in [
      {'status': 'pending'},
      {'dateTime': '2026-11-02T10:00:00Z'},
      {'vetId': ''},
      {'queueId': 'existing'},
    ]) {
      await appointment('a', patch: patch);
      await expectLater(
        repository.checkInAppointment(
          appointmentId: 'a',
          hospitalId: 'hospital',
        ),
        throwsStateError,
      );
    }
    expect((await db.collection('queue_records').get()).docs, isEmpty);
    expect(
      (await db.collection('hospitals/hospital/queue_days').get()).docs,
      isEmpty,
    );
  });

  test(
    'status commands enforce the full lifecycle and stamp transitions',
    () async {
      final queue = await repository.checkInAppointment(
        appointmentId: 'a',
        hospitalId: 'hospital',
      );
      Future<dynamic> transition(
        StaffQueueStatus expected,
        StaffQueueStatus next, {
        String hospital = 'hospital',
      }) => repository.transitionStatus(
        queueId: queue.queueId,
        hospitalId: hospital,
        expectedStatus: expected,
        nextStatus: next,
      );
      await expectLater(
        transition(StaffQueueStatus.waiting, StaffQueueStatus.completed),
        throwsStateError,
      );
      await expectLater(
        transition(
          StaffQueueStatus.waiting,
          StaffQueueStatus.called,
          hospital: 'other',
        ),
        throwsStateError,
      );
      final calledQueue = await transition(
        StaffQueueStatus.waiting,
        StaffQueueStatus.called,
      );
      expect(calledQueue.status, 'called');
      expect(calledQueue.calledAt, isNotNull);
      expect(calledQueue.consultationStartedAt, isNull);
      await expectLater(
        transition(StaffQueueStatus.called, StaffQueueStatus.completed),
        throwsStateError,
      );
      await expectLater(
        transition(StaffQueueStatus.waiting, StaffQueueStatus.called),
        throwsStateError,
      );
      final inConsultation = await transition(
        StaffQueueStatus.called,
        StaffQueueStatus.inConsultation,
      );
      expect(inConsultation.consultationStartedAt, isNotNull);
      final completed = await transition(
        StaffQueueStatus.inConsultation,
        StaffQueueStatus.completed,
      );
      expect(completed.status, 'completed');
      expect(completed.completedAt, isNotNull);
      await expectLater(
        transition(StaffQueueStatus.completed, StaffQueueStatus.called),
        throwsStateError,
      );
    },
  );

  test('skipped and cancelled entries are terminal', () async {
    final skippedQueue = await repository.checkInAppointment(
      appointmentId: 'a',
      hospitalId: 'hospital',
    );
    final skipped = await repository.transitionStatus(
      queueId: skippedQueue.queueId,
      hospitalId: 'hospital',
      expectedStatus: StaffQueueStatus.waiting,
      nextStatus: StaffQueueStatus.skipped,
    );
    expect(skipped.status, 'skipped');
    expect(skipped.skippedAt, isNotNull);
    await expectLater(
      repository.transitionStatus(
        queueId: skippedQueue.queueId,
        hospitalId: 'hospital',
        expectedStatus: StaffQueueStatus.skipped,
        nextStatus: StaffQueueStatus.called,
      ),
      throwsStateError,
    );

    await appointment('b');
    final cancelledQueue = await repository.checkInAppointment(
      appointmentId: 'b',
      hospitalId: 'hospital',
    );
    final cancelled = await repository.transitionStatus(
      queueId: cancelledQueue.queueId,
      hospitalId: 'hospital',
      expectedStatus: StaffQueueStatus.waiting,
      nextStatus: StaffQueueStatus.cancelled,
    );
    expect(cancelled.status, 'cancelled');
    expect(cancelled.cancelledAt, isNotNull);
    await expectLater(
      repository.transitionStatus(
        queueId: cancelledQueue.queueId,
        hospitalId: 'hospital',
        expectedStatus: StaffQueueStatus.cancelled,
        nextStatus: StaffQueueStatus.waiting,
      ),
      throwsStateError,
    );
  });

  test('legacy scoped lookup works with string timestamps', () async {
    await db.doc('queue_records/legacy').set({
      'queueId': 'legacy',
      'appointmentId': 'a',
      'hospitalId': 'hospital',
      'ownerId': 'owner',
      'petId': 'pet',
      'queueNumber': 9,
      'currentServing': 0,
      'position': 9,
      'status': 'waiting',
      'updatedAt': today.toIso8601String(),
    });
    expect((await repository.getQueueByAppointment('a'))!.queueId, 'legacy');
    await expectLater(
      repository.checkInAppointment(appointmentId: 'a', hospitalId: 'hospital'),
      throwsStateError,
    );
  });

  test(
    'UTC evening and local legacy dates use the Colombo calendar day',
    () async {
      repository = FirebaseQueueRepository(
        firestore: db,
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'staff'),
          signedIn: true,
        ),
        now: () => DateTime.utc(2026, 11, 2, 20),
      );
      await appointment('a', patch: {'dateTime': '2026-11-03T00:15:00.000'});
      await repository.checkInAppointment(
        appointmentId: 'a',
        hospitalId: 'hospital',
      );
      expect(
        (await db.doc('hospitals/hospital/queue_days/2026-11-03').get()).exists,
        isTrue,
      );
      await appointment('b', patch: {'dateTime': '2026-11-02T20:00:00.000Z'});
      expect(
        (await repository.checkInAppointment(
          appointmentId: 'b',
          hospitalId: 'hospital',
        )).queueNumber,
        2,
      );
    },
  );

  test('timestamp records deserialize', () async {
    final queue = await repository.checkInAppointment(
      appointmentId: 'a',
      hospitalId: 'hospital',
    );
    await db.doc('queue_records/${queue.queueId}').update({
      'updatedAt': Timestamp.fromDate(today),
    });
    expect(
      (await repository.getQueueById(queue.queueId))!.updatedAt.toUtc(),
      today,
    );
  });
  test(
    'daily counters reset and hospital counters remain independent',
    () async {
      await db.doc('hospitals/hospital/queue_days/2026-11-02').set({
        'lastNumber': 50,
      });
      await repository.checkInAppointment(
        appointmentId: 'a',
        hospitalId: 'hospital',
      );
      await db.doc('hospital_staff/staff').update({'hospitalId': 'other'});
      await appointment('b', patch: {'hospitalId': 'other'});
      final queue = await repository.checkInAppointment(
        appointmentId: 'b',
        hospitalId: 'other',
      );
      expect(queue.queueNumber, 1);
    },
  );

  test(
    'timestamp appointments normalize without changing appointment storage',
    () async {
      await appointment(
        'a',
        patch: {
          'dateTime': Timestamp.fromDate(today),
          'createdAt': Timestamp.fromDate(today),
        },
      );
      await repository.checkInAppointment(
        appointmentId: 'a',
        hospitalId: 'hospital',
      );
      expect(
        (await db.doc('appointments/a').get()).data()!['dateTime'],
        isA<Timestamp>(),
      );
    },
  );

  test('missing and malformed appointments fail before allocation', () async {
    await expectLater(
      repository.checkInAppointment(
        appointmentId: 'missing',
        hospitalId: 'hospital',
      ),
      throwsStateError,
    );
    await appointment('a', patch: {'dateTime': 'invalid'});
    await expectLater(
      repository.checkInAppointment(appointmentId: 'a', hospitalId: 'hospital'),
      throwsFormatException,
    );
    expect((await db.collection('queue_records').get()).docs, isEmpty);
  });
}
