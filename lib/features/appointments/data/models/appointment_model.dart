import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.appointmentId,
    required super.ownerId,
    required super.petId,
    required super.hospitalId,
    required super.serviceId,
    required super.vetId,
    required super.dateTime,
    required super.reason,
    required super.status,
    super.queueId,
    required super.createdAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      appointmentId: map['appointmentId'] as String,
      ownerId: map['ownerId'] as String,
      petId: map['petId'] as String,
      hospitalId: map['hospitalId'] as String,
      serviceId: map['serviceId'] as String,
      vetId: map['vetId'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      reason: map['reason'] as String,
      status: map['status'] as String,
      queueId: map['queueId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  factory AppointmentModel.fromEntity(Appointment appointment) {
    return AppointmentModel(
      appointmentId: appointment.appointmentId,
      ownerId: appointment.ownerId,
      petId: appointment.petId,
      hospitalId: appointment.hospitalId,
      serviceId: appointment.serviceId,
      vetId: appointment.vetId,
      dateTime: appointment.dateTime,
      reason: appointment.reason,
      status: appointment.status,
      queueId: appointment.queueId,
      createdAt: appointment.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'ownerId': ownerId,
      'petId': petId,
      'hospitalId': hospitalId,
      'serviceId': serviceId,
      'vetId': vetId,
      'dateTime': dateTime.toIso8601String(),
      'reason': reason,
      'status': status,
      'queueId': queueId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
