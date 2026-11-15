import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/entities/hospital_operating_hours.dart';
import 'package:petcare/features/appointments/domain/utils/appointment_slot_generator.dart';

const _operatingHours = HospitalOperatingHours(
  openingMinutes: 8 * 60,
  closingMinutes: 12 * 60,
);

const _veterinarianId = 'vet_001';

Appointment _testAppointment({
  required String status,
  String veterinarianId = _veterinarianId,
  DateTime? dateTime,
}) {
  return Appointment(
    appointmentId: 'appointment_001',
    ownerId: 'owner_001',
    petId: 'pet_001',
    hospitalId: 'hospital_001',
    serviceId: 'service_001',
    vetId: veterinarianId,
    dateTime: dateTime ?? DateTime(2026, 11, 1, 9),
    reason: 'Checkup',
    status: status,
    createdAt: DateTime(2026, 10, 31),
  );
}

void main() {
  group('AppointmentSlotGenerator', () {
    test('8 AM to 8 PM exposes 48 fifteen-minute slots', () {
      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 10),
        operatingHours: const HospitalOperatingHours(
          openingMinutes: 480,
          closingMinutes: 1200,
        ),
        serviceDurationMinutes: 15,
        veterinarianId: _veterinarianId,
        existingAppointments: const [],
        appointmentDurations: const {},
      );
      expect(slots, hasLength(48));
      expect(slots.first.startTime, DateTime(2026, 11, 10, 8));
      expect(slots.last.startTime, DateTime(2026, 11, 10, 19, 45));
      expect(slots.last.endTime, DateTime(2026, 11, 10, 20));
    });
    test('a genuinely fully booked date has no available slots', () {
      final date = DateTime(2026, 11, 20);
      final bookings = List.generate(
        48,
        (index) => Appointment(
          appointmentId: 'booked_$index',
          ownerId: 'owner',
          petId: 'pet',
          hospitalId: 'hospital',
          serviceId: 'service',
          vetId: _veterinarianId,
          dateTime: DateTime(
            2026,
            11,
            20,
            8,
          ).add(Duration(minutes: index * 15)),
          reason: '',
          status: 'confirmed',
          createdAt: DateTime(2026, 11, 1),
        ),
      );
      final slots = AppointmentSlotGenerator.generate(
        date: date,
        operatingHours: const HospitalOperatingHours(
          openingMinutes: 480,
          closingMinutes: 1200,
        ),
        serviceDurationMinutes: 15,
        veterinarianId: _veterinarianId,
        existingAppointments: bookings,
        appointmentDurations: {
          for (final booking in bookings)
            booking.appointmentId: const Duration(minutes: 15),
        },
      );
      expect(slots, isEmpty);
    });
    test('generates slots within hospital operating hours', () {
      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: const [],
        appointmentDurations: const {},
      );

      expect(slots, hasLength(15));
      expect(slots.first.startTime, DateTime(2026, 11, 1, 8));
      expect(slots.first.endTime, DateTime(2026, 11, 1, 8, 30));
      expect(slots[1].startTime, DateTime(2026, 11, 1, 8, 15));
      expect(slots.last.startTime, DateTime(2026, 11, 1, 11, 30));
      expect(slots.last.endTime, DateTime(2026, 11, 1, 12));
    });

    test('does not generate a slot beyond closing time', () {
      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 60,
        veterinarianId: _veterinarianId,
        existingAppointments: const [],
        appointmentDurations: const {},
      );

      expect(slots, hasLength(13));
      expect(slots.last.endTime, DateTime(2026, 11, 1, 12));
    });

    test('ignores appointments belonging to another veterinarian', () {
      final appointment = _testAppointment(
        status: 'pending',
        veterinarianId: 'vet_002',
        dateTime: DateTime(2026, 11, 1, 8),
      );

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(slots.first.startTime, DateTime(2026, 11, 1, 8));
    });

    test('pending appointments continue to reserve their slots', () {
      final appointment = _testAppointment(status: 'pending');

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isFalse,
      );

      expect(slots, hasLength(12));
    });

    test('confirmed appointments continue to reserve their slots', () {
      final appointment = _testAppointment(status: 'confirmed');

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isFalse,
      );

      expect(slots, hasLength(12));
    });

    test('rejected appointments release their reserved slots', () {
      final appointment = _testAppointment(status: 'rejected');

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(slots, hasLength(15));
      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isTrue,
      );
    });

    test('cancelled appointments release their reserved slots', () {
      final appointment = _testAppointment(status: 'cancelled');

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(slots, hasLength(15));
      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isTrue,
      );
    });

    test('unknown appointment statuses remain reserved for safety', () {
      final appointment = _testAppointment(status: 'unknown_status');

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isFalse,
      );
    });

    test('removes slots overlapping an existing appointment', () {
      final appointment = _testAppointment(status: 'pending');

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isFalse,
      );

      expect(slots, hasLength(12));
    });

    test('handles existing appointments with different service durations', () {
      final appointment = _testAppointment(
        status: 'pending',
        dateTime: DateTime(2026, 11, 1, 9),
      );

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 60)},
      );

      // The existing appointment occupies 09:00-10:00.
      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isFalse,
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9, 30)),
        isFalse,
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 10)),
        isTrue,
      );
    });

    test('treats an appointment with unknown duration as occupied', () {
      final appointment = _testAppointment(status: 'pending');

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: const {},
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isFalse,
      );
    });

    test('excludes slots that have already started', () {
      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: _operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: _veterinarianId,
        existingAppointments: const [],
        appointmentDurations: const {},
        now: DateTime(2026, 11, 1, 10, 15),
      );

      expect(slots.map((slot) => slot.startTime), [
        DateTime(2026, 11, 1, 10, 30),
        DateTime(2026, 11, 1, 10, 45),
        DateTime(2026, 11, 1, 11),
        DateTime(2026, 11, 1, 11, 15),
        DateTime(2026, 11, 1, 11, 30),
      ]);
    });

    test(
      'does not filter future slots when now is before the selected day',
      () {
        final slots = AppointmentSlotGenerator.generate(
          date: DateTime(2026, 11, 2),
          operatingHours: _operatingHours,
          serviceDurationMinutes: 30,
          veterinarianId: _veterinarianId,
          existingAppointments: const [],
          appointmentDurations: const {},
          now: DateTime(2026, 11, 1, 23, 59),
        );

        expect(slots, hasLength(15));
        expect(slots.first.startTime, DateTime(2026, 11, 2, 8));
      },
    );

    test('throws when requested service duration is zero', () {
      expect(
        () => AppointmentSlotGenerator.generate(
          date: DateTime(2026, 11, 1),
          operatingHours: _operatingHours,
          serviceDurationMinutes: 0,
          veterinarianId: _veterinarianId,
          existingAppointments: const [],
          appointmentDurations: const {},
        ),
        throwsArgumentError,
      );
    });

    test('throws when requested service duration is negative', () {
      expect(
        () => AppointmentSlotGenerator.generate(
          date: DateTime(2026, 11, 1),
          operatingHours: _operatingHours,
          serviceDurationMinutes: -30,
          veterinarianId: _veterinarianId,
          existingAppointments: const [],
          appointmentDurations: const {},
        ),
        throwsArgumentError,
      );
    });
  });
}
