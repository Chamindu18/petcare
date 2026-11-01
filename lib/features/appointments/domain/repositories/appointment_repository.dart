import '../entities/appointment.dart';

abstract interface class AppointmentRepository {
  Future<Appointment> createAppointment(Appointment appointment);

  Future<List<Appointment>> getAppointments();

  Future<Appointment?> getAppointmentById(String appointmentId);

  Future<void> updateAppointment(Appointment appointment);

  Future<void> cancelAppointment(String appointmentId);

  /// Confirms a pending appointment.
  Future<void> confirmAppointment(String appointmentId);

  /// Rejects a pending appointment.
  Future<void> rejectAppointment(String appointmentId);
}
