import '../entities/appointment_slot.dart';
import '../entities/hospital_operating_hours.dart';
import '../repositories/appointment_availability_repository.dart';
import '../utils/appointment_slot_generator.dart';

/// Generates available appointment slots for a veterinarian.
class GetAvailableAppointmentSlots {
  const GetAvailableAppointmentSlots(this._repository);

  final AppointmentAvailabilityRepository _repository;

  /// Returns slots that can accommodate the requested service.
  ///
  /// Existing appointments belonging to other veterinarians are ignored.
  /// Existing appointments for the selected veterinarian are checked for
  /// overlap using their actual service durations.
  Future<List<AppointmentSlot>> call({
    required DateTime date,
    required String veterinarianId,
    required HospitalOperatingHours operatingHours,
    required int serviceDurationMinutes,
  }) async {
    final availability = await _repository.getAvailabilityForVeterinarian(
      veterinarianId: veterinarianId,
      date: date,
    );

    return AppointmentSlotGenerator.generate(
      date: date,
      operatingHours: operatingHours,
      serviceDurationMinutes: serviceDurationMinutes,
      veterinarianId: veterinarianId,
      existingAppointments: availability.appointments,
      appointmentDurations: availability.appointmentDurations,
    );
  }
}
