import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../appointments/data/models/appointment_model.dart';
import '../../../hospital_staff/domain/utils/staff_queue_eligibility.dart';

import '../../domain/entities/queue.dart';
import '../../domain/repositories/queue_repository.dart';
import '../models/queue_model.dart';
import '../../../notifications/data/notification_event.dart';

/// Authorized queue reads and atomic staff queue commands.
class FirebaseQueueRepository
    implements QueueRepository, StaffQueueCommandRepository {
  FirebaseQueueRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    DateTime Function()? now,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _now = now ?? DateTime.now;

  final FirebaseAuth _auth;
  final DateTime Function() _now;

  // MVP hospitals use Asia/Colombo, independently of the device timezone.
  static DateTime _day(DateTime instant) {
    final local = instant.toUtc().add(const Duration(minutes: 330));
    return DateTime.utc(local.year, local.month, local.day);
  }

  Future<void> _verifyStaff(Transaction tx, String hospitalId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || hospitalId.isEmpty || hospitalId == 'unassigned') {
      throw StateError('An active hospital staff assignment is required.');
    }
    final user = await tx.get(_firestore.collection('users').doc(uid));
    final assignment = await tx.get(
      _firestore.collection('hospital_staff').doc(uid),
    );
    final data = assignment.data();
    if (user.data()?['role'] != 'veterinary_staff' ||
        data?['userId'] != uid ||
        data?['hospitalId'] != hospitalId ||
        data?['active'] != true) {
      throw StateError('An active hospital staff assignment is required.');
    }
  }

  final FirebaseFirestore _firestore;

  // Reference to the queue records collection.
  CollectionReference<Map<String, dynamic>> get _queueCollection =>
      _firestore.collection('queue_records');

  @override
  Future<Queue?> getQueueByAppointment(String appointmentId) async {
    final appointment = await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .get();
    final data = appointment.data();
    if (data == null) return null;
    final linkedId = data['queueId'] as String?;
    if (linkedId != null && linkedId.isNotEmpty) {
      final queue = await getQueueById(linkedId);
      if (queue != null && queue.appointmentId != appointmentId) {
        throw StateError('Queue linkage does not match the appointment.');
      }
      return queue;
    }
    // Legacy records without linkage still require provable query scope.
    final uid = _auth.currentUser?.uid;
    final scope = data['ownerId'] == uid ? 'ownerId' : 'hospitalId';
    final snapshot = await _queueCollection
        .where(scope, isEqualTo: data[scope])
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty
        ? null
        : QueueModel.fromMap(snapshot.docs.first.data());
  }

  @override
  Future<Queue?> getQueueById(String queueId) async {
    // Get one queue record by its document ID.
    final document = await _queueCollection.doc(queueId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null) {
      return null;
    }

    return QueueModel.fromMap(data);
  }

  @override
  Future<Queue> checkInAppointment({
    required String appointmentId,
    required String hospitalId,
  }) async {
    // Detect safely readable legacy queues before attempting a new allocation.
    if (await getQueueByAppointment(appointmentId) != null) {
      throw StateError('This appointment has already been added to a queue.');
    }
    final appointmentRef = _firestore
        .collection('appointments')
        .doc(appointmentId);
    final day = _day(_now());
    final key = day.toIso8601String().substring(0, 10);
    final counterRef = _firestore
        .collection('hospitals')
        .doc(hospitalId)
        .collection('queue_days')
        .doc(key);
    final queueRef = _queueCollection.doc();
    await _firestore.runTransaction((tx) async {
      await _verifyStaff(tx, hospitalId);
      final snapshot = await tx.get(appointmentRef);
      if (!snapshot.exists) throw StateError('Appointment not found.');
      final appointmentData = {
        ...snapshot.data()!,
        'appointmentId': snapshot.id,
      };
      for (final field in ['dateTime', 'createdAt']) {
        final value = appointmentData[field];
        if (value is Timestamp) {
          appointmentData[field] = value.toDate().toUtc().toIso8601String();
        }
      }
      final appointment = AppointmentModel.fromMap(appointmentData);
      // Feed calendar components to the existing pure validator, avoiding device timezone.
      final storedDate = appointmentData['dateTime'] as String;
      // Offset-free legacy dates are hospital wall time, not device wall time.
      final scheduled = storedDate.endsWith('Z')
          ? _day(appointment.dateTime)
          : DateTime.utc(
              appointment.dateTime.year,
              appointment.dateTime.month,
              appointment.dateTime.day,
            );
      final result = StaffQueueEligibility.evaluate(
        appointment: AppointmentModel.fromMap({
          ...appointmentData,
          'dateTime': DateTime(
            scheduled.year,
            scheduled.month,
            scheduled.day,
          ).toIso8601String(),
        }),
        assignedHospitalId: hospitalId,
        now: DateTime(day.year, day.month, day.day),
      );
      if (!result.isEligible) throw StateError(result.message!);
      final counter = await tx.get(counterRef);
      final number = counter.exists
          ? (counter.data()!['lastNumber'] as int) + 1
          : 1;
      tx.set(counterRef, {
        'lastNumber': number,
        'queueId': queueRef.id,
        'day': Timestamp.fromDate(day),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(queueRef, {
        'queueId': queueRef.id,
        'appointmentId': appointmentId,
        'hospitalId': hospitalId,
        'ownerId': appointment.ownerId,
        'petId': appointment.petId,
        'veterinarianId': appointment.vetId,
        'queueNumber': number,
        'currentServing': 0,
        'position': number,
        'status': 'waiting',
        'day': Timestamp.fromDate(day),
        'dayKey': key,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(appointmentRef, {
        'queueId': queueRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      NotificationEvent.create(
        tx,
        _firestore,
        recipientId: appointment.ownerId,
        type: 'queue_checked_in',
        message: 'Your pet was checked in to the queue.',
        targetType: 'queue',
        targetId: queueRef.id,
        details: {'queueNumber': number},
      );
    });
    return (await getQueueById(queueRef.id))!;
  }

  @override
  Future<List<Queue>> getHospitalQueue({
    required String hospitalId,
    required DateTime date,
  }) async {
    // A calendar date, as specified by the command contract (not an instant).
    final day = DateTime.utc(date.year, date.month, date.day);
    await _firestore.runTransaction((tx) => _verifyStaff(tx, hospitalId));
    final snapshot = await _queueCollection
        .where('hospitalId', isEqualTo: hospitalId)
        .where('day', isEqualTo: Timestamp.fromDate(day))
        .get();
    final queues = snapshot.docs
        .map((doc) => QueueModel.fromMap(doc.data()))
        .toList();
    queues.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
    return queues;
  }

  @override
  Future<Queue> transitionStatus({
    required String queueId,
    required String hospitalId,
    required StaffQueueStatus expectedStatus,
    required StaffQueueStatus nextStatus,
  }) async {
    if (!expectedStatus.canTransitionTo(nextStatus)) {
      throw StateError('Invalid queue status transition.');
    }

    final timestampField = switch (nextStatus) {
      QueueStatus.called => 'calledAt',
      QueueStatus.inConsultation => 'consultationStartedAt',
      QueueStatus.completed => 'completedAt',
      QueueStatus.skipped => 'skippedAt',
      QueueStatus.cancelled => 'cancelledAt',
      QueueStatus.waiting => throw StateError(
        'Queue cannot transition back to waiting.',
      ),
    };

    final ref = _queueCollection.doc(queueId);
    await _firestore.runTransaction((tx) async {
      await _verifyStaff(tx, hospitalId);
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (data == null ||
          data['hospitalId'] != hospitalId ||
          data['status'] != expectedStatus.value) {
        throw StateError(
          'Queue not found, unauthorized, or status has changed.',
        );
      }
      tx.update(ref, {
        'status': nextStatus.value,
        'position': 0,
        timestampField: FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      NotificationEvent.create(
        tx,
        _firestore,
        recipientId: data['ownerId'] as String,
        type: nextStatus == StaffQueueStatus.inConsultation
            ? 'queue_in_consultation'
            : 'queue_completed',
        message: nextStatus == StaffQueueStatus.inConsultation
            ? "Your pet's consultation has begun."
            : "Your pet's consultation is complete.",
        targetType: 'queue',
        targetId: queueId,
        details: {'queueNumber': data['queueNumber']},
      );
    });
    return (await getQueueById(queueId))!;
  }
}
