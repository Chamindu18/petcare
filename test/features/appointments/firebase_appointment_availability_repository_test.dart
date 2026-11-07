import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/appointments/data/repositories/firebase_appointment_availability_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirebaseAppointmentAvailabilityRepository repository;

  final selectedDay = DateTime(2026, 11, 10);

  setUp(() {
    db = FakeFirebaseFirestore();
    repository = FirebaseAppointmentAvailabilityRepository(firestore: db);
  });

  Future<void> addService(String serviceId, int duration) {
    return db.doc('services/$serviceId').set({
      'hospitalId': 'hospital-a',
      'duration': duration,
    });
  }

  Future<void> addSchedule(
    String appointmentId, {
    required String vetId,
    required DateTime dateTime,
    required String serviceId,
    String status = 'pending',
    int? durationMinutes,
  }) {
    return db.doc('appointment_schedule/$appointmentId').set({
      'vetId': vetId,
      'hospitalId': 'hospital-a',
      'serviceId': serviceId,
      'dateTime': dateTime.toUtc().toIso8601String(),
      'status': status,
      'durationMinutes': ?durationMinutes,
    });
  }

  test('reads only privacy-preserving schedule projections', () async {
    await db.doc('appointments/canonical-only').set({
      'ownerId': 'owner-a',
      'petId': 'pet-a',
      'hospitalId': 'hospital-a',
      'serviceId': 'service-a',
      'vetId': 'vet-a',
      'dateTime': selectedDay.toUtc().toIso8601String(),
      'status': 'pending',
    });

    final canonicalOnly = await repository.getAvailabilityForVeterinarian(
      veterinarianId: 'vet-a',
      date: selectedDay,
    );

    expect(canonicalOnly.appointments, isEmpty);

    await addService('service-a', 30);
    await addSchedule(
      'projected',
      vetId: 'vet-a',
      dateTime: selectedDay,
      serviceId: 'service-a',
      durationMinutes: 30,
    );

    final projected = await repository.getAvailabilityForVeterinarian(
      veterinarianId: 'vet-a',
      date: selectedDay,
    );

    expect(projected.appointments.single.appointmentId, 'projected');
  });

  test(
    'prefers a duration snapshot and falls back to the service duration',
    () async {
      await addService('service-a', 30);
      await addService('service-b', 45);

      await addSchedule(
        'snapshot',
        vetId: 'vet-a',
        dateTime: selectedDay.add(const Duration(hours: 9)),
        serviceId: 'service-a',
        durationMinutes: 60,
      );
      await addSchedule(
        'legacy',
        vetId: 'vet-a',
        dateTime: selectedDay.add(const Duration(hours: 10)),
        serviceId: 'service-b',
      );

      final availability = await repository.getAvailabilityForVeterinarian(
        veterinarianId: 'vet-a',
        date: selectedDay,
      );

      expect(
        availability.appointmentDurations['snapshot'],
        const Duration(minutes: 60),
      );
      expect(
        availability.appointmentDurations['legacy'],
        const Duration(minutes: 45),
      );
    },
  );

  test(
    'includes only the selected day and known overnight reservations',
    () async {
      await addService('service-a', 30);

      await addSchedule(
        'selected',
        vetId: 'vet-a',
        dateTime: selectedDay.add(const Duration(hours: 9)),
        serviceId: 'service-a',
        durationMinutes: 30,
      );
      await addSchedule(
        'overnight',
        vetId: 'vet-a',
        dateTime: selectedDay.subtract(const Duration(minutes: 15)),
        serviceId: 'service-a',
        durationMinutes: 30,
      );
      await addSchedule(
        'previous-finished',
        vetId: 'vet-a',
        dateTime: selectedDay.subtract(const Duration(hours: 2)),
        serviceId: 'service-a',
        durationMinutes: 30,
      );
      await addSchedule(
        'next-day',
        vetId: 'vet-a',
        dateTime: selectedDay.add(const Duration(days: 1, hours: 9)),
        serviceId: 'service-a',
        durationMinutes: 30,
      );

      final availability = await repository.getAvailabilityForVeterinarian(
        veterinarianId: 'vet-a',
        date: selectedDay,
      );

      expect(
        availability.appointments.map(
          (appointment) => appointment.appointmentId,
        ),
        unorderedEquals(['selected', 'overnight']),
      );
    },
  );

  test('ignores previous-day reservations with unknown durations', () async {
    await addSchedule(
      'unknown-overnight',
      vetId: 'vet-a',
      dateTime: selectedDay.subtract(const Duration(minutes: 15)),
      serviceId: 'missing-service',
    );

    final availability = await repository.getAvailabilityForVeterinarian(
      veterinarianId: 'vet-a',
      date: selectedDay,
    );

    expect(availability.appointments, isEmpty);
    expect(availability.appointmentDurations, isEmpty);
  });

  test('keeps same-day reservations with unknown durations occupied', () async {
    await addSchedule(
      'unknown-today',
      vetId: 'vet-a',
      dateTime: selectedDay.add(const Duration(hours: 9)),
      serviceId: 'missing-service',
    );

    final availability = await repository.getAvailabilityForVeterinarian(
      veterinarianId: 'vet-a',
      date: selectedDay,
    );

    expect(availability.appointments.single.appointmentId, 'unknown-today');
    expect(availability.appointmentDurations, isEmpty);
  });
}
