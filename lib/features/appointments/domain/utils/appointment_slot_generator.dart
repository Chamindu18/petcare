import '../entities/appointment.dart';
import '../entities/appointment_slot.dart';
import '../entities/hospital_operating_hours.dart';

/// Generates available appointment slots for a veterinarian.
///
/// The generator is intentionally independent of Firebase, Flutter, and
/// service repositories. Existing appointment durations are supplied by the
/// caller so the domain logic can correctly detect overlapping appointments
/// with different service lengths.
class AppointmentSlotGenerator {
  const AppointmentSlotGenerator._();

  /// Generates non-overlapping slots within the hospital's operating hours.
  ///
  /// [date] determines the calendar day for the generated slots.
  /// [operatingHours] defines the hospital opening and closing times.
  /// [serviceDurationMinutes] defines the duration of the requested service.
  /// [veterinarianId] limits conflicts to the selected veterinarian.
  /// [existingAppointments] contains appointments that may occupy slots.
  /// [appointmentDurations] maps appointment IDs to their actual service
  /// durations.
  /// [now] excludes slots that have already started. It is optional so
  /// callers can generate a full day for display or testing.
  ///
  /// Rejected and cancelled appointments do not reserve slots.
  /// Pending and confirmed appointments remain reserved.
  /// Unknown statuses are treated as occupied for safety.
  static List<AppointmentSlot> generate({
    required DateTime date,
    required HospitalOperatingHours operatingHours,
    required int serviceDurationMinutes,
    required String veterinarianId,
    required List<Appointment> existingAppointments,
    required Map<String, Duration> appointmentDurations,
    DateTime? now,
  }) {
    if (serviceDurationMinutes <= 0) {
      throw ArgumentError.value(
        serviceDurationMinutes,
        'serviceDurationMinutes',
        'Service duration must be greater than zero.',
      );
    }

    final dayStart = DateTime(
      date.year,
      date.month,
      date.day,
      operatingHours.openingMinutes ~/ 60,
      operatingHours.openingMinutes % 60,
    );

    final dayEnd = DateTime(
      date.year,
      date.month,
      date.day,
      operatingHours.closingMinutes ~/ 60,
      operatingHours.closingMinutes % 60,
    );

    final requestedDuration = Duration(minutes: serviceDurationMinutes);
    final slots = <AppointmentSlot>[];

    var slotStart = dayStart;

    while (!slotStart.add(requestedDuration).isAfter(dayEnd)) {
      final slotEnd = slotStart.add(requestedDuration);

      // A slot that has already started cannot be booked, even when its
      // remaining time has not fully elapsed.
      if (now != null && !slotStart.isAfter(now)) {
        slotStart = slotEnd;
        continue;
      }

      final overlapsExistingAppointment = existingAppointments.any((
        appointment,
      ) {
        // Rejected and cancelled appointments release their reservations.
        final status = appointment.status.trim().toLowerCase();

        if (status == 'rejected' || status == 'cancelled') {
          return false;
        }

        if (appointment.vetId != veterinarianId) {
          return false;
        }

        final existingDuration =
            appointmentDurations[appointment.appointmentId];

        // Unknown duration is treated as occupied for safety.
        if (existingDuration == null || existingDuration <= Duration.zero) {
          return true;
        }

        final existingStart = appointment.dateTime;
        final existingEnd = existingStart.add(existingDuration);

        return existingStart.isBefore(slotEnd) &&
            existingEnd.isAfter(slotStart);
      });

      if (!overlapsExistingAppointment) {
        slots.add(AppointmentSlot(startTime: slotStart, endTime: slotEnd));
      }

      slotStart = slotEnd;
    }

    return slots;
  }
}
