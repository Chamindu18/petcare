class Appointment {
  const Appointment({
    required this.appointmentId,
    required this.ownerId,
    required this.petId,
    required this.hospitalId,
    required this.serviceId,
    required this.vetId,
    required this.dateTime,
    required this.reason,
    required this.status,
    this.queueId,
    required this.createdAt,
  });

  final String appointmentId;
  final String ownerId;
  final String petId;
  final String hospitalId;
  final String serviceId;
  final String vetId;
  final DateTime dateTime;
  final String reason;
  final String status;
  final String? queueId;
  final DateTime createdAt;
}
