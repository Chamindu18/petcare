/// Canonical lifecycle state for a hospital queue entry.
///
/// Appointment status is a separate workflow and must not be changed by
/// queue operations.
enum QueueStatus {
  waiting('waiting'),
  called('called'),
  inConsultation('in_consultation'),
  completed('completed'),
  skipped('skipped'),
  cancelled('cancelled');

  const QueueStatus(this.value);

  /// Canonical value stored in the queue record.
  final String value;

  /// Converts a stored value into a known queue status.
  static QueueStatus fromValue(String value) {
    final status = tryParse(value);

    if (status == null) {
      throw FormatException('Unsupported queue status: $value');
    }

    return status;
  }

  /// Converts a stored value into a status, or null when unsupported.
  static QueueStatus? tryParse(String? value) {
    if (value == null) return null;

    final normalized = value.trim().toLowerCase();

    for (final status in QueueStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }

    return null;
  }

  /// Whether this status is no longer part of the active queue.
  bool get isTerminal =>
      this == QueueStatus.completed ||
      this == QueueStatus.skipped ||
      this == QueueStatus.cancelled;

  /// Whether the entry still needs staff action.
  bool get isActive => !isTerminal;

  /// Whether the patient is waiting to be called.
  bool get isWaiting => this == QueueStatus.waiting;

  /// Whether the patient has been called or is in consultation.
  bool get isInProgress =>
      this == QueueStatus.called || this == QueueStatus.inConsultation;
}
