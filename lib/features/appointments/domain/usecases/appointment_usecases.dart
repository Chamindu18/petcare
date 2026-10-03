import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

/// Creates a new appointment.
class CreateAppointment {
  const CreateAppointment(this._repository);

  final AppointmentRepository _repository;

  // Save the appointment through the repository.
  Future<Appointment> call(Appointment appointment) {
    return _repository.createAppointment(appointment);
  }
}

/// Gets all appointments belonging to the current owner.
class GetAppointments {
  const GetAppointments(this._repository);

  final AppointmentRepository _repository;

  // Get the owner's appointments from the repository.
  Future<List<Appointment>> call() {
    return _repository.getAppointments();
  }
}

/// Gets one appointment using its ID.
class GetAppointmentById {
  const GetAppointmentById(this._repository);

  final AppointmentRepository _repository;

  // Return null when the appointment cannot be found or accessed.
  Future<Appointment?> call(String appointmentId) {
    return _repository.getAppointmentById(appointmentId);
  }
}

/// Updates an existing appointment.
class UpdateAppointment {
  const UpdateAppointment(this._repository);

  final AppointmentRepository _repository;

  // Pass the updated appointment to the repository.
  Future<void> call(Appointment appointment) {
    return _repository.updateAppointment(appointment);
  }
}
