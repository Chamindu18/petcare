import '../entities/queue.dart';
import '../repositories/queue_repository.dart';

/// Gets queue information for an appointment.
class GetQueueByAppointment {
  const GetQueueByAppointment(this._repository);

  final QueueRepository _repository;

  // Get the queue through the repository.
  Future<Queue?> call(String appointmentId) {
    return _repository.getQueueByAppointment(appointmentId);
  }
}

/// Gets one queue record by its ID.
class GetQueueById {
  const GetQueueById(this._repository);

  final QueueRepository _repository;

  // Get the queue through the repository.
  Future<Queue?> call(String queueId) {
    return _repository.getQueueById(queueId);
  }
}
