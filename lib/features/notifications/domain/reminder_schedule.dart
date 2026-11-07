class ReminderSchedule {
  static DateTime? appointment(DateTime appointmentTime, DateTime now) {
    final when = appointmentTime.subtract(const Duration(hours: 24));
    return when.isAfter(now) ? when : null;
  }

  /// Vaccination due dates are calendar dates, with no medical time inferred.
  /// Remind at 09:00 the day before, or shortly after a late record update.
  static DateTime? vaccination(DateTime dueDate, DateTime now) {
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final today = DateTime(now.year, now.month, now.day);
    if (!dueDay.isAfter(today)) return null;
    final planned = DateTime(dueDate.year, dueDate.month, dueDate.day - 1, 9);
    return planned.isAfter(now) ? planned : now.add(const Duration(minutes: 1));
  }
}
