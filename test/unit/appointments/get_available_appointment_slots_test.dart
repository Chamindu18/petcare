import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/entities/hospital_operating_hours.dart';
import 'package:petcare/features/appointments/domain/entities/veterinarian_availability.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_availability_repository.dart';
import 'package:petcare/features/appointments/domain/usecases/get_available_appointment_slots.dart';

class FakeAppointmentAvailabilityRepository
    implements AppointmentAvailabilityRepository {
  FakeAppointmentAvailabilityRepository({
    required this.availability,
    this.error,
  });

  final VeterinarianAvailability availability;
  final Exception? error;

  @override
  Future<VeterinarianAvailability> getAvailabilityForVeterinarian({
    required String veterinarianId,
    required DateTime date,
  }) async {
    if (error != null) {
      throw error!;
    }

    return availability;
  }
}

void main() {
  const veterinarianId = 'vet_001';

  final operatingHours = HospitalOperatingHours(
    openingMinutes: 8 * 60,
    closingMinutes: 12 * 60,
  );

  group('GetAvailableAppointmentSlots', () {
    test('returns available slots when existing appointments are present', () async {
      final existingAppointment = Appointment(
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

      final repository = FakeAppointmentAvailabilityRepository(
        availability: VeterinarianAvailability(
          appointments: [existingAppointment],
          appointmentDurations: {
            'appointment_001': const Duration(minutes: 30),
          },
        ),
      );

      final useCase = GetAvailableAppointmentSlots(repository);

      final slots = await useCase(
        date: DateTime(2026, 11, 1),
        veterinarianId: veterinarianId,
        operatingHours: operatingHours,
        serviceDurationMinutes: 30,
      );

      expect(slots, hasLength(7));
      expect(
        slots.any(
          (slot) => slot.startTime == DateTime(2026, 11, 1, 9),
        ),
        isFalse,
      );
    });

    test('returns all valid slots when there are no existing appointments',
        () async {
      final repository = FakeAppointmentAvailabilityRepository(
        availability: const VeterinarianAvailability(
          appointments: [],
          appointmentDurations: {},
        ),
      );

      final useCase = GetAvailableAppointmentSlots(repository);

      final slots = await useCase(
        date: DateTime(2026, 11, 1),
        veterinarianId: veterinarianId,
        operatingHours: operatingHours,
        serviceDurationMinutes: 30,
      );

      expect(slots, hasLength(8));
      expect(
        slots.first.startTime,
        DateTime(2026, 11, 1, 8),
      );
      expect(
        slots.last.startTime,
        DateTime(2026, 11, 1, 11, 30),
      );
    });

    test('propagates repository errors', () async {
      final repository = FakeAppointmentAvailabilityRepository(
        availability: const VeterinarianAvailability(
          appointments: [],
          appointmentDurations: {},
        ),
        error: Exception('Availability service unavailable'),
      );

      final useCase = GetAvailableAppointmentSlots(repository);

      expect(
        () => useCase(
          date: DateTime(2026, 11, 1),
          veterinarianId: veterinarianId,
          operatingHours: operatingHours,
          serviceDurationMinutes: 30,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}