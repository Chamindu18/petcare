import '../entities/appointment.dart';

/// Calendar-based classification for appointment presentation.
///
/// This utility does not mutate appointment records or change their
/// Firestore status. It only determines where an appointment appears.
///
/// All calendar comparisons use the device's local timezone. The
/// caller can inject [now] for deterministic testing.
enum AppointmentDateCategory { overdue, today, tomorrow, upcoming, history }

class AppointmentDateClassifier {
  const AppointmentDateClassifier._();

  /// Returns the calendar category of an appointment.
  ///
  /// Pending and confirmed appointments are considered active.
  /// Cancelled, rejected, completed, and unknown statuses belong
  /// to history regardless of their appointment dates.
  static AppointmentDateCategory classify(
    Appointment appointment, {
    DateTime? now,
  }) {
    if (!isActive(appointment)) {
      return AppointmentDateCategory.history;
    }

    final currentDate = (now ?? DateTime.now()).toLocal();
    final appointmentDate = appointment.dateTime.toLocal();

    final today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    final scheduledDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );

    if (scheduledDay.isBefore(today)) {
      return AppointmentDateCategory.overdue;
    }

    if (scheduledDay.isAtSameMomentAs(today)) {
      return AppointmentDateCategory.today;
    }

    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    if (scheduledDay.isAtSameMomentAs(tomorrow)) {
      return AppointmentDateCategory.tomorrow;
    }

    return AppointmentDateCategory.upcoming;
  }

  /// Whether the appointment remains in the scheduling workflow.
  ///
  /// An appointment is not automatically completed or cancelled
  /// when its scheduled time passes.
  static bool isActive(Appointment appointment) {
    final status = appointment.status.trim().toLowerCase();

    return status == 'pending' || status == 'confirmed';
  }

  /// Whether the appointment should appear on the assigned
  /// veterinarian's confirmed appointment shortlist.
  ///
  /// Future appointments are intentionally included so doctors
  /// can review tomorrow's and later appointments in advance.
  ///
  /// The calling repository must independently enforce the
  /// authenticated veterinarian and hospital assignment.
  static bool isConfirmedForVeterinarian(
    Appointment appointment, {
    DateTime? now,
  }) {
    if (appointment.status.trim().toLowerCase() != 'confirmed') {
      return false;
    }

    final category = classify(appointment, now: now);

    return category == AppointmentDateCategory.today ||
        category == AppointmentDateCategory.tomorrow ||
        category == AppointmentDateCategory.upcoming;
  }

  /// Returns active appointments in chronological order.
  ///
  /// The input collection is never mutated.
  static List<Appointment> activeSorted(Iterable<Appointment> appointments) {
    return appointments.where(isActive).toList()
      ..sort((first, second) => first.dateTime.compareTo(second.dateTime));
  }
}
