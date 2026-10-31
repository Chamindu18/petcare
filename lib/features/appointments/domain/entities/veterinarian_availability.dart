import 'appointment.dart';

/// Contains the appointment data required to calculate veterinarian
/// availability for a specific date.
class VeterinarianAvailability {
  const VeterinarianAvailability({
    required this.appointments,
    required this.appointmentDurations,
  });

  /// Existing appointments for the selected veterinarian and date.
  final List<Appointment> appointments;

  /// Maps each appointment ID to the duration of its service.
  ///
  /// An appointment may be absent from this map when its service duration
  /// cannot be resolved. The slot generator treats such appointments as
  /// occupied for safety.
  final Map<String, Duration> appointmentDurations;
}
