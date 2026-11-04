/// Represents a hospital appointment's queue record.
///
/// The appointment, hospital, owner, and pet relationships are immutable.
/// Queue operations may update operational fields such as status,
/// position, current serving number, and updatedAt.
///
/// Firestore security rules independently enforce access permissions
/// and protect immutable relationship fields.
class Queue {
  const Queue({
    required this.queueId,
    required this.appointmentId,
    required this.queueNumber,
    required this.currentServing,
    required this.position,
    required this.status,
    required this.updatedAt,
    this.hospitalId = '',
    this.ownerId = '',
    this.petId = '',
  });

  /// Unique Firestore queue document identifier.
  final String queueId;

  /// The appointment associated with this queue entry.
  final String appointmentId;

  /// Hospital authorized to manage this queue entry.
  ///
  /// This must match the hospital on the verified appointment.
  final String hospitalId;

  /// Owner of the appointment.
  ///
  /// This must be copied from the verified appointment record.
  final String ownerId;

  /// Pet receiving veterinary care.
  ///
  /// This must be copied from the verified appointment record.
  final String petId;

  /// Queue number assigned when the patient checks in.
  final int queueNumber;

  /// Queue number currently being served.
  final int currentServing;

  /// Position of the patient in the queue.
  final int position;

  /// Queue lifecycle state.
  ///
  /// Supported values will be defined and validated by the
  /// queue workflow before write operations are implemented.
  final String status;

  /// Last time this queue record was updated.
  final DateTime updatedAt;

  /// Whether all required relationship identifiers are present.
  ///
  /// This provides defensive domain validation, not authorization.
  /// Repositories must independently verify relationships using
  /// trusted appointment data and Firestore security rules.
  bool get hasValidRelationships =>
      queueId.trim().isNotEmpty &&
      appointmentId.trim().isNotEmpty &&
      hospitalId.trim().isNotEmpty &&
      ownerId.trim().isNotEmpty &&
      petId.trim().isNotEmpty;

  /// Whether the operational queue number and position are valid.
  ///
  /// Queue numbers are positive integers. Position is allowed
  /// to be zero when the patient is being served or has finished.
  bool get hasValidQueueNumbers =>
      queueNumber > 0 && currentServing >= 0 && position >= 0;
}
