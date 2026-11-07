import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/appointments/data/repositories/firebase_appointment_repository.dart';
import 'package:petcare/features/appointments/data/datasources/appointment_scheduling_datasource.dart';
import 'package:petcare/features/appointments/data/repositories/firebase_appointment_availability_repository.dart';
import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/data/models/appointment_model.dart';
import 'package:petcare/features/veterinary/data/repositories/firebase_veterinarian_assignment_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirebaseAppointmentRepository repository;
  late _SchedulingDataSource scheduling;
  final date = DateTime(2026, 11, 10, 9);
  Appointment appointment({String vetId = 'directory-a', DateTime? at}) =>
      Appointment(
        appointmentId: '',
        ownerId: 'spoofed',
        petId: 'pet',
        hospitalId: 'hospital-a',
        serviceId: 'service',
        vetId: vetId,
        dateTime: at ?? date,
        reason: 'Checkup',
        status: 'pending',
        createdAt: date,
      );

  setUp(() async {
    db = FakeFirebaseFirestore();
    scheduling = _SchedulingDataSource();
    repository = FirebaseAppointmentRepository(
      schedulingDataSource: scheduling,
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'owner'), signedIn: true),
    );
    await db.doc('services/service').set({
      'hospitalId': 'hospital-a',
      'duration': 30,
    });
    for (final id in ['directory-a', 'directory-b']) {
      await db.doc('veterinarians/$id').set({
        'vetId': id,
        'hospitalId': 'hospital-a',
        'userId': id == 'directory-a' ? 'doctor' : 'doctor-b',
        'active': true,
        'name': id,
      });
    }
  });

  test(
    'booking delegates to the trusted scheduler with a canonical UTC request',
    () async {
      final saved = await repository.createAppointment(appointment());
      expect(saved.ownerId, 'owner');
      expect(scheduling.requests.single['action'], 'create');
      expect(
        scheduling.requests.single['dateTime'],
        date.toUtc().toIso8601String(),
      );
      expect(scheduling.requests.single.containsKey('ownerId'), isFalse);
      expect((await db.collection('appointments').get()).docs, isEmpty);
    },
  );

  test(
    'rescheduling and staff reassignment use the same trusted boundary',
    () async {
      await repository.updateAppointment(appointment());
      await repository.reassignVeterinarian(
        appointmentId: 'a',
        hospitalId: 'hospital-a',
        vetId: 'directory-b',
      );
      expect(scheduling.requests.map((r) => r['action']), [
        'update',
        'reassign',
      ]);
      expect(scheduling.requests.last['hospitalId'], 'hospital-a');
      expect(scheduling.requests.last['vetId'], 'directory-b');
    },
  );

  test(
    'server conflict failure does not fall back to a direct Firestore write',
    () async {
      scheduling.failure = StateError('This time is no longer available.');
      await expectLater(
        repository.createAppointment(appointment()),
        throwsStateError,
      );
      await expectLater(
        repository.reassignVeterinarian(
          appointmentId: 'a',
          hospitalId: 'hospital-a',
          vetId: 'directory-b',
        ),
        throwsStateError,
      );
      expect((await db.collection('appointments').get()).docs, isEmpty);
      expect((await db.collection('appointment_schedule').get()).docs, isEmpty);
    },
  );

  test('status updates preserve snapshotted duration and do not change queue records', () async {
    final data = scheduling.response('a', date);
    data['durationMinutes'] = 30;
    data['queueId'] = 'q';
    await db.doc('appointments/a').set(data);
    await db.doc('queue_records/q').set({'status': 'waiting'});
    await repository.confirmAppointment('a');
    expect(
      (await db.doc('appointment_schedule/a').get()).data()!['durationMinutes'],
      30,
    );
    expect(
      (await db.doc('queue_records/q').get()).data()!['status'],
      'waiting',
    );
    final availability = await FirebaseAppointmentAvailabilityRepository(
      firestore: db,
    ).getAvailabilityForVeterinarian(veterinarianId: 'directory-a', date: date);
    expect(availability.appointmentDurations['a'], const Duration(minutes: 30));
  });

  test('canonical IDs and Timestamp legacy appointments load', () async {
    await db.doc('appointments/legacy').set({
      'ownerId': 'owner',
      'petId': 'pet',
      'hospitalId': 'hospital-a',
      'serviceId': 'service',
      'vetId': 'directory-a',
      'dateTime': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(date),
      'reason': 'Checkup',
      'status': 'pending',
    });
    final loaded = (await repository.getAppointments()).single;
    expect(loaded.appointmentId, 'legacy');
    expect(loaded.dateTime, date);
  });

  test(
    'server UTC dates are converted for local calendar and clock displays',
    () {
      final utc = DateTime.utc(2026, 11, 10, 4);
      for (final value in [utc.toIso8601String(), Timestamp.fromDate(utc)]) {
        final model = AppointmentModel.fromMap({
          ...scheduling.response('utc', date),
          'dateTime': value,
          'createdAt': value,
        });
        expect(model.dateTime.isUtc, isFalse);
        expect(model.dateTime, utc.toLocal());
        expect(model.createdAt.isUtc, isFalse);
      }
    },
  );

  test(
    'availability includes reservations crossing the selected midnight',
    () async {
      final previousDay = DateTime(2026, 11, 9, 23, 45);
      await db.doc('appointment_schedule/overnight').set({
        'vetId': 'directory-a',
        'hospitalId': 'hospital-a',
        'serviceId': 'service',
        'status': 'confirmed',
        'dateTime': previousDay.toUtc().toIso8601String(),
        'durationMinutes': 30,
      });
      final availability =
          await FirebaseAppointmentAvailabilityRepository(firestore: db)
              .getAvailabilityForVeterinarian(
                veterinarianId: 'directory-a',
                date: date,
              );
      expect(availability.appointments.single.appointmentId, 'overnight');
      expect(
        availability.appointmentDurations['overnight'],
        const Duration(minutes: 30),
      );
    },
  );

  test('account assignment verifies directory identity, hospital and active status', () async {
    final assignment = FirebaseVeterinarianAssignmentRepository(
      firestore: db,
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'doctor'), signedIn: true),
    );
    await db.doc('users/doctor').set({
      'role': 'veterinarian',
      'vetId': 'directory-a',
      'hospitalId': 'hospital-a',
    });
    expect((await assignment.getCurrentAssignment())?.vetId, 'directory-a');
    for (final patch in [
      {'active': false},
      {'active': true, 'userId': 'impostor'},
      {'userId': 'doctor', 'hospitalId': 'hospital-b'},
      {'hospitalId': 'hospital-a', 'vetId': null},
    ]) {
      await db.doc('veterinarians/directory-a').update(patch);
      expect(await assignment.getCurrentAssignment(), isNull);
    }
  });
}

class _SchedulingDataSource implements AppointmentSchedulingDataSource {
  final requests = <Map<String, dynamic>>[];
  Object? failure;
  Map<String, dynamic> response(String id, DateTime date) => {
    'appointmentId': id,
    'ownerId': 'owner',
    'petId': 'pet',
    'hospitalId': 'hospital-a',
    'serviceId': 'service',
    'vetId': 'directory-a',
    'dateTime': date.toIso8601String(),
    'reason': 'Checkup',
    'status': 'pending',
    'createdAt': date.toIso8601String(),
  };
  @override
  Future<Map<String, dynamic>> reserve(Map<String, dynamic> request) async {
    requests.add(request);
    if (failure != null) throw failure!;
    return response(
      request['appointmentId'] as String,
      DateTime(2026, 11, 10, 9),
    );
  }
}
