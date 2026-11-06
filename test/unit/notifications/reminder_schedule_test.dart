import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/notifications/domain/reminder_schedule.dart';

void main() {
  test('confirmed appointment reminder is exactly 24 hours earlier', () {
    final now = DateTime(2026, 11, 6, 10);
    expect(
      ReminderSchedule.appointment(DateTime(2026, 11, 8, 12), now),
      DateTime(2026, 11, 7, 12),
    );
    expect(
      ReminderSchedule.appointment(DateTime(2026, 11, 7, 9), now),
      isNull,
    );
  });

  test('vaccination reminder uses only the existing due date', () {
    final now = DateTime(2026, 11, 6, 10);
    expect(
      ReminderSchedule.vaccination(DateTime(2026, 11, 9), now),
      DateTime(2026, 11, 8, 9),
    );
    expect(
      ReminderSchedule.vaccination(DateTime(2026, 11, 7), now),
      DateTime(2026, 11, 6, 10, 1),
    );
    expect(ReminderSchedule.vaccination(DateTime(2026, 11, 6), now), isNull);
  });
}
