import '../entities/queue.dart';

/// Defines how the application accesses queue information.
abstract interface class QueueRepository {
  // Get queue information for an appointment.
  Future<Queue?> getQueueByAppointment(String appointmentId);

  // Get one queue record by its ID.
  Future<Queue?> getQueueById(String queueId);
}
