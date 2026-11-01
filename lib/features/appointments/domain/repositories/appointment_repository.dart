import '../entities/appointment.dart';

abstract interface class AppointmentRepository {
  Future<Appointment> createAppointment(Appointment appointment);

  Future<List<Appointment>> getAppointments();

  /// Returns all appointments belonging to a hospital.
  ///
  /// Used by veterinary staff to manage appointments for their hospital.
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId);

  /// Returns appointments assigned to a veterinarian within a hospital.
  ///
  /// The hospital scope provides an additional authorization boundary.
  Future<List<Appointment>> getAppointmentsByVeterinarian({
    required String vetId,
    required String hospitalId,
  });

  Future<Appointment?> getAppointmentById(String appointmentId);

  Future<void> updateAppointment(Appointment appointment);

  Future<void> cancelAppointment(String appointmentId);

  /// Confirms a pending appointment.
  Future<void> confirmAppointment(String appointmentId);

  /// Rejects a pending appointment.
  Future<void> rejectAppointment(String appointmentId);
}
