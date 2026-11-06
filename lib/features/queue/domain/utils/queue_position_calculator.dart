import '../entities/queue.dart';
import '../entities/queue_status.dart';

/// Derives waiting positions without adding stored position writes.
///
/// Callers must provide queue entries from one hospital and one hospital day.
/// Terminal, called, and in-consultation entries do not consume a waiting
/// position.
class QueuePositionCalculator {
  const QueuePositionCalculator._();

  /// Returns waiting positions keyed by queue ID.
  ///
  /// Waiting entries are ordered by their allocated queue number. Invalid or
  /// unsupported statuses are excluded from the result.
  static Map<String, int> calculate({
    required String hospitalId,
    required Iterable<Queue> hospitalDayEntries,
  }) {
    final normalizedHospitalId = hospitalId.trim();

    final waitingEntries =
        hospitalDayEntries
            .where(
              (entry) =>
                  entry.hospitalId == normalizedHospitalId &&
                  entry.queueStatus == QueueStatus.waiting,
            )
            .toList()
          ..sort((a, b) {
            final byNumber = a.queueNumber.compareTo(b.queueNumber);
            return byNumber != 0 ? byNumber : a.queueId.compareTo(b.queueId);
          });

    return {
      for (var index = 0; index < waitingEntries.length; index++)
        waitingEntries[index].queueId: index + 1,
    };
  }

  /// Returns the derived waiting position for [entry], or zero when the entry
  /// is not currently waiting.
  static int positionFor({
    required Queue entry,
    required Iterable<Queue> hospitalDayEntries,
  }) {
    if (entry.queueStatus != QueueStatus.waiting) return 0;

    return calculate(
          hospitalId: entry.hospitalId,
          hospitalDayEntries: hospitalDayEntries,
        )[entry.queueId] ??
        0;
  }
}
