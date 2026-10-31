import '../entities/veterinarian_availability.dart';

/// Provides appointment data required to calculate veterinarian availability.
///
/// Implementations may use different data sources. The domain layer does not
/// assume how cross-owner appointment data is authorized or retrieved.
abstract interface class AppointmentAvailabilityRepository {
  /// Returns appointments for [veterinarianId] occurring on [date].
  ///
  /// The implementation is responsible for retrieving only appointments
  /// relevant to the requested veterinarian and calendar day.
  Future<VeterinarianAvailability> getAvailabilityForVeterinarian({
    required String veterinarianId,
    required DateTime date,
  });
}
