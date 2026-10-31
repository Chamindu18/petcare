import '../entities/appointment.dart';

/// Provides appointment data required to calculate veterinarian availability.
///
/// Implementations may use different data sources. The domain layer does not
/// assume how cross-owner appointment data is authorized or retrieved.
abstract interface class AppointmentAvailabilityRepository {
  /// Returns appointments for [veterinarianId] occurring on [date].
  ///
  /// The implementation is responsible for retrieving only appointments
  /// relevant to the requested veterinarian and calendar day.
  Future<List<Appointment>> getAppointmentsForVeterinarian({
    required String veterinarianId,
    required DateTime date,
  });
}
