import '../../domain/entities/queue.dart';

/// Converts Firestore queue data into a domain Queue.
class QueueModel extends Queue {
  const QueueModel({
    required super.queueId,
    required super.appointmentId,
    required super.queueNumber,
    required super.currentServing,
    required super.position,
    required super.status,
    required super.updatedAt,
  });

  /// Creates a QueueModel from Firestore data.
  factory QueueModel.fromMap(Map<String, dynamic> map) {
    return QueueModel(
      queueId: map['queueId'] as String,
      appointmentId: map['appointmentId'] as String,
      queueNumber: map['queueNumber'] as int,
      currentServing: map['currentServing'] as int,
      position: map['position'] as int,
      status: map['status'] as String,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Converts the model into Firestore-compatible data.
  Map<String, dynamic> toMap() {
    return {
      'queueId': queueId,
      'appointmentId': appointmentId,
      'queueNumber': queueNumber,
      'currentServing': currentServing,
      'position': position,
      'status': status,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
