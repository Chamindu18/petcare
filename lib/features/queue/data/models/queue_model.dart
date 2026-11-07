import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/queue.dart';

/// Firestore representation of a hospital appointment queue record.
///
/// Existing legacy documents may not contain all relationship fields.
/// Those records remain readable, but cannot be serialized for writes
/// until their relationships have been verified and populated.
class QueueModel extends Queue {
  const QueueModel({
    required super.queueId,
    required super.appointmentId,
    required super.queueNumber,
    required super.currentServing,
    required super.position,
    required super.status,
    required super.updatedAt,
    required super.hospitalId,
    required super.ownerId,
    required super.petId,
    super.veterinarianId = '',
    super.queueSequence = '',
    super.createdAt,
    super.calledAt,
    super.consultationStartedAt,
    super.completedAt,
    super.skippedAt,
    super.cancelledAt,
  });

  /// Converts an existing Firestore document into a queue model.
  ///
  /// Missing relationship fields default to empty strings for
  /// backward-compatible reads. An empty relationship field never
  /// authorizes a new write.
  ///
  /// Malformed required fields throw instead of silently creating
  /// a valid-looking queue record.
  factory QueueModel.fromMap(Map<String, dynamic> map) {
    return QueueModel(
      queueId: map['queueId'] as String,
      appointmentId: map['appointmentId'] as String,
      queueNumber: map['queueNumber'] as int,
      currentServing: map['currentServing'] as int,
      position: map['position'] as int,
      status: map['status'] as String,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
      hospitalId: _optionalRelationship(map, 'hospitalId'),
      ownerId: _optionalRelationship(map, 'ownerId'),
      petId: _optionalRelationship(map, 'petId'),
      veterinarianId: _optionalRelationship(map, 'veterinarianId'),
      queueSequence: _optionalRelationship(map, 'queueSequence'),
      createdAt: _optionalTimestamp(map, 'createdAt'),
      calledAt: _optionalTimestamp(map, 'calledAt'),
      consultationStartedAt: _optionalTimestamp(map, 'consultationStartedAt'),
      completedAt: _optionalTimestamp(map, 'completedAt'),
      skippedAt: _optionalTimestamp(map, 'skippedAt'),
      cancelledAt: _optionalTimestamp(map, 'cancelledAt'),
    );
  }

  /// Converts a domain queue record into its Firestore representation.
  factory QueueModel.fromEntity(Queue queue) {
    return QueueModel(
      queueId: queue.queueId,
      appointmentId: queue.appointmentId,
      queueNumber: queue.queueNumber,
      currentServing: queue.currentServing,
      position: queue.position,
      status: queue.status,
      updatedAt: queue.updatedAt,
      hospitalId: queue.hospitalId,
      ownerId: queue.ownerId,
      petId: queue.petId,
      veterinarianId: queue.veterinarianId,
      queueSequence: queue.queueSequence,
      createdAt: queue.createdAt,
      calledAt: queue.calledAt,
      consultationStartedAt: queue.consultationStartedAt,
      completedAt: queue.completedAt,
      skippedAt: queue.skippedAt,
      cancelledAt: queue.cancelledAt,
    );
  }

  /// Serializes a queue record for Firestore persistence.
  ///
  /// Rejects missing relationships and invalid queue numbers before
  /// a repository attempts a write. Firestore authorization must still
  /// independently verify these values against trusted records.
  Map<String, dynamic> toMap() {
    if (!hasValidRelationships) {
      throw StateError(
        'Queue record is missing required relationship identifiers.',
      );
    }

    if (!hasValidQueueNumbers) {
      throw StateError(
        'Queue record contains invalid queue numbers or position.',
      );
    }

    if (status.trim().isEmpty) {
      throw StateError('Queue record status cannot be empty.');
    }

    final map = <String, dynamic>{
      'queueId': queueId,
      'appointmentId': appointmentId,
      'hospitalId': hospitalId,
      'ownerId': ownerId,
      'petId': petId,
      'queueNumber': queueNumber,
      'currentServing': currentServing,
      'position': position,
      'status': status,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };

    if (veterinarianId.trim().isNotEmpty) {
      map['veterinarianId'] = veterinarianId;
    }

    if (queueSequence.trim().isNotEmpty) {
      map['queueSequence'] = queueSequence;
    }

    _putTimestamp(map, 'createdAt', createdAt);
    _putTimestamp(map, 'calledAt', calledAt);
    _putTimestamp(map, 'consultationStartedAt', consultationStartedAt);
    _putTimestamp(map, 'completedAt', completedAt);
    _putTimestamp(map, 'skippedAt', skippedAt);
    _putTimestamp(map, 'cancelledAt', cancelledAt);

    return map;
  }

  static void _putTimestamp(
    Map<String, dynamic> map,
    String field,
    DateTime? value,
  ) {
    if (value != null) {
      map[field] = value.toUtc().toIso8601String();
    }
  }

  static DateTime? _optionalTimestamp(Map<String, dynamic> map, String field) {
    final value = map[field];

    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);

      if (parsed == null) {
        throw FormatException(
          'Queue timestamp field "$field" must be a valid date.',
        );
      }

      return parsed;
    }

    throw FormatException(
      'Queue timestamp field "$field" must be a timestamp or string.',
    );
  }

  /// Preserves readability of legacy documents with absent
  /// relationship fields, without accepting malformed non-string data.
  static String _optionalRelationship(Map<String, dynamic> map, String field) {
    final value = map[field];

    if (value == null) {
      return '';
    }

    if (value is! String) {
      throw FormatException(
        'Queue relationship field "$field" must be a string.',
      );
    }

    return value;
  }
}
