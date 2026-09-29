import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

/// Creates a new appointment through the repository.
class CreateAppointment {
  const CreateAppointment(this._repository);

  final AppointmentRepository _repository;

  // Pass the appointment to the data layer and return the saved result.
  Future<Appointment> call(Appointment appointment) {
    return _repository.createAppointment(appointment);
  }
}
