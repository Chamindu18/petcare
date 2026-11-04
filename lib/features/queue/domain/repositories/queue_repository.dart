import '../entities/queue.dart';

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

/// Supported operational states for a hospital queue entry.
///
/// Appointment confirmation and cancellation are separate workflows.
/// Queue status must not be used to modify appointment status.
enum StaffQueueStatus {
  waiting('waiting'),
  inConsultation('in_consultation'),
  completed('completed');

  const StaffQueueStatus(this.value);

  /// Canonical value stored in the queue record.
  final String value;

  /// Converts a stored value into a known queue status.
  ///
  /// Unknown states are rejected instead of being silently treated
  /// as waiting or completed.
  static StaffQueueStatus fromValue(String value) {
    final normalized = value.trim().toLowerCase();

    for (final status in StaffQueueStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }

    throw FormatException('Unsupported queue status: $value');
  }
}

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
  /// waiting -> in_consultation -> completed
  ///
  /// The expected status provides optimistic concurrency protection:
  /// a transaction must reject the operation if the persisted status
  /// has changed since it was read.
  ///
  /// Completed entries cannot be reopened through this workflow.
  Future<Queue> transitionStatus({
    required String queueId,
    required String hospitalId,
    required StaffQueueStatus expectedStatus,
    required StaffQueueStatus nextStatus,
  });
}
