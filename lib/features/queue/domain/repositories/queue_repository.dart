import '../entities/queue.dart';
import '../entities/queue_status.dart';

export '../entities/queue_status.dart' show QueueStatus;

/// Read-only access to queue information.
///
/// Existing consumers can continue using this interface without
/// depending on hospital staff queue-management operations.
abstract interface class QueueRepository {
  /// Returns queue information linked to an appointment.
  Future<Queue?> getQueueByAppointment(String appointmentId);

  /// Returns a queue record by its document identifier.
  Future<Queue?> getQueueById(String queueId);
}

/// Owner-scoped queue position reads.
///
/// The server must verify that the queue entry belongs to the authenticated
/// owner before calculating a position from hospital queue entries.
abstract interface class OwnerQueueRepository {
  /// Returns the owner's current waiting position, or null when unavailable.
  ///
  /// A positive value means the number of waiting entries ahead, including
  /// the owner's entry. Zero means the entry is not waiting.
  Future<int?> getOwnerQueuePosition({required String queueId});
}

/// Backward-compatible staff name for the full queue lifecycle.
///
/// Existing staff commands only issue the waiting, in-consultation,
/// and completed transitions.
typedef StaffQueueStatus = QueueStatus;

/// Contract for hospital staff queue-management operations.
///
/// Implementations must validate authenticated hospital access,
/// verify appointment relationships, and use atomic transactions
/// for mutations. Client-provided identifiers are not proof of
/// authorization.
abstract interface class StaffQueueCommandRepository {
  /// Checks in an eligible appointment and returns its queue entry.
  ///
  /// Required implementation guarantees:
  /// - The caller has an active, verified hospital assignment.
  /// - The appointment belongs to that hospital.
  /// - The appointment is confirmed and scheduled for today.
  /// - The appointment has not already been checked in.
  /// - Queue numbering is concurrency-safe.
  /// - Queue creation and appointment linkage are atomic.
  ///
  /// The repository must reject duplicate attempts rather than
  /// allocating multiple queue numbers for one appointment.
  Future<Queue> checkInAppointment({
    required String appointmentId,
    required String hospitalId,
  });

  /// Returns queue records for one hospital and calendar date.
  ///
  /// The implementation must query with a hospital restriction,
  /// verify the requested date, and avoid returning records from
  /// another hospital.
  ///
  /// [date] represents the hospital's intended local calendar day.
  Future<List<Queue>> getHospitalQueue({
    required String hospitalId,
    required DateTime date,
  });

  /// Performs one valid operational queue status transition.
  ///
  /// Allowed transitions:
  /// waiting -> called -> in_consultation -> completed
  ///
  /// Waiting and called entries may also be skipped or cancelled, and an
  /// in-consultation entry may be cancelled. Terminal entries cannot be
  /// reopened or changed through this workflow.
  ///
  /// The expected status provides optimistic concurrency protection:
  /// a transaction must reject the operation if the persisted status
  /// has changed since it was read.
  Future<Queue> transitionStatus({
    required String queueId,
    required String hospitalId,
    required StaffQueueStatus expectedStatus,
    required StaffQueueStatus nextStatus,
  });
}

/// Contract for the authenticated veterinarian's assigned queue.
///
/// Reads and commands are scoped to the verified veterinarian and hospital.
/// Implementations must reject queues assigned to another veterinarian.
abstract interface class VeterinarianQueueRepository {
  /// Returns today's queue entries assigned to one verified veterinarian.
  Future<List<Queue>> getVeterinarianQueue({
    required String hospitalId,
    required String veterinarianId,
    required DateTime date,
  });

  /// Performs one valid operational transition on the veterinarian's queue.
  Future<Queue> transitionStatus({
    required String queueId,
    required String hospitalId,
    required StaffQueueStatus expectedStatus,
    required StaffQueueStatus nextStatus,
  });
}
