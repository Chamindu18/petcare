import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/entities/hospital_operating_hours.dart';
import 'package:petcare/features/appointments/domain/utils/appointment_slot_generator.dart';

void main() {
  group('AppointmentSlotGenerator', () {
    const operatingHours = HospitalOperatingHours(
      openingMinutes: 8 * 60,
      closingMinutes: 12 * 60,
    );

    const veterinarianId = 'vet_001';

    test('generates slots within hospital operating hours', () {
      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: veterinarianId,
        existingAppointments: const [],
        appointmentDurations: const {},
      );

      expect(slots, hasLength(8));
      expect(slots.first.startTime, DateTime(2026, 11, 1, 8));
      expect(slots.first.endTime, DateTime(2026, 11, 1, 8, 30));
      expect(slots.last.startTime, DateTime(2026, 11, 1, 11, 30));
      expect(slots.last.endTime, DateTime(2026, 11, 1, 12));
    });

    test('does not generate a slot beyond closing time', () {
      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: operatingHours,
        serviceDurationMinutes: 60,
        veterinarianId: veterinarianId,
        existingAppointments: const [],
        appointmentDurations: const {},
      );

      expect(slots, hasLength(4));
      expect(slots.last.endTime, DateTime(2026, 11, 1, 12));
    });

    test('ignores appointments belonging to another veterinarian', () {
      final appointment = Appointment(
        appointmentId: 'appointment_001',
        ownerId: 'owner_001',
        petId: 'pet_001',
        hospitalId: 'hospital_001',
        serviceId: 'service_001',
        vetId: 'vet_002',
        dateTime: DateTime(2026, 11, 1, 8),
        reason: 'Checkup',
        status: 'pending',
        createdAt: DateTime(2026, 10, 31),
      );

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(slots.first.startTime, DateTime(2026, 11, 1, 8));
    });

    test('removes slots overlapping an existing appointment', () {
      final appointment = Appointment(
        appointmentId: 'appointment_001',
        ownerId: 'owner_001',
        petId: 'pet_001',
        hospitalId: 'hospital_001',
        serviceId: 'service_001',
        vetId: veterinarianId,
        dateTime: DateTime(2026, 11, 1, 9),
        reason: 'Checkup',
        status: 'pending',
        createdAt: DateTime(2026, 10, 31),
      );

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 30)},
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isFalse,
      );

      expect(slots, hasLength(7));
    });

    test('handles existing appointments with different service durations', () {
      final appointment = Appointment(
        appointmentId: 'appointment_001',
        ownerId: 'owner_001',
        petId: 'pet_001',
        hospitalId: 'hospital_001',
        serviceId: 'service_002',
        vetId: veterinarianId,
        dateTime: DateTime(2026, 11, 1, 9),
        reason: 'Dental checkup',
        status: 'pending',
        createdAt: DateTime(2026, 10, 31),
      );

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: {'appointment_001': const Duration(minutes: 60)},
      );

      // The existing appointment occupies 09:00-10:00,
      // so both 09:00 and 09:30 slots must be unavailable.
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
      final appointment = Appointment(
        appointmentId: 'appointment_001',
        ownerId: 'owner_001',
        petId: 'pet_001',
        hospitalId: 'hospital_001',
        serviceId: 'service_001',
        vetId: veterinarianId,
        dateTime: DateTime(2026, 11, 1, 9),
        reason: 'Checkup',
        status: 'pending',
        createdAt: DateTime(2026, 10, 31),
      );

      final slots = AppointmentSlotGenerator.generate(
        date: DateTime(2026, 11, 1),
        operatingHours: operatingHours,
        serviceDurationMinutes: 30,
        veterinarianId: veterinarianId,
        existingAppointments: [appointment],
        appointmentDurations: const {},
      );

      expect(
        slots.any((slot) => slot.startTime == DateTime(2026, 11, 1, 9)),
        isFalse,
      );
    });

    test('throws when requested service duration is zero', () {
      expect(
        () => AppointmentSlotGenerator.generate(
          date: DateTime(2026, 11, 1),
          operatingHours: operatingHours,
          serviceDurationMinutes: 0,
          veterinarianId: veterinarianId,
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
          operatingHours: operatingHours,
          serviceDurationMinutes: -30,
          veterinarianId: veterinarianId,
          existingAppointments: const [],
          appointmentDurations: const {},
        ),
        throwsArgumentError,
      );
    });
  });
}
