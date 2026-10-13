/// Represents the queue information for an appointment
class Queue {
  const Queue({
    required this.queueId,
    required this.appointmentId,
    required this.queueNumber,
    required this.currentServing,
    required this.position,
    required this.status,
    required this.updatedAt,
  });

  final String queueId;
  final String appointmentId;
  final int queueNumber;
  final int currentServing;
  final int position;
  final String status;
  final DateTime updatedAt;
}
