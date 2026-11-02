import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

/// Creates a new appointment.
class CreateAppointment {
  const CreateAppointment(this._repository);

  final AppointmentRepository _repository;

  /// Saves the appointment through the repository.
  Future<Appointment> call(Appointment appointment) {
    return _repository.createAppointment(appointment);
  }
}

/// Gets all appointments belonging to the current owner.
class GetAppointments {
  const GetAppointments(this._repository);

  final AppointmentRepository _repository;

  /// Gets the owner's appointments from the repository.
  Future<List<Appointment>> call() {
    return _repository.getAppointments();
  }
}

/// Gets one appointment using its ID.
class GetAppointmentById {
  const GetAppointmentById(this._repository);

  final AppointmentRepository _repository;

  /// Returns null when the appointment cannot be found or accessed.
  Future<Appointment?> call(String appointmentId) {
    return _repository.getAppointmentById(appointmentId);
  }
}

/// Updates an existing appointment.
class UpdateAppointment {
  const UpdateAppointment(this._repository);

  final AppointmentRepository _repository;

  /// Passes the updated appointment to the repository.
  Future<void> call(Appointment appointment) {
    return _repository.updateAppointment(appointment);
  }
}

/// Confirms a pending appointment.
///
/// This action is intended for authorized veterinary staff.
class ConfirmAppointment {
  const ConfirmAppointment(this._repository);

  final AppointmentRepository _repository;

  Future<void> call(String appointmentId) {
    return _repository.confirmAppointment(appointmentId);
  }
}

/// Rejects a pending appointment.
///
/// This action is intended for authorized veterinary staff.
class RejectAppointment {
  const RejectAppointment(this._repository);

  final AppointmentRepository _repository;

  Future<void> call(String appointmentId) {
    return _repository.rejectAppointment(appointmentId);
  }
}

/// Gets all appointments belonging to a hospital.
class GetAppointmentsByHospital {
  const GetAppointmentsByHospital(this._repository);

  final AppointmentRepository _repository;

  Future<List<Appointment>> call(String hospitalId) {
    return _repository.getAppointmentsByHospital(hospitalId);
  }
}

/// Gets appointments assigned to a veterinarian within a hospital.
class GetAppointmentsByVeterinarian {
  const GetAppointmentsByVeterinarian(this._repository);

  final AppointmentRepository _repository;

  Future<List<Appointment>> call({
    required String vetId,
    required String hospitalId,
  }) {
    return _repository.getAppointmentsByVeterinarian(
      vetId: vetId,
      hospitalId: hospitalId,
    );
  }
}
