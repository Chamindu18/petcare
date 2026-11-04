import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/utils/appointment_date_classifier.dart';

/// Creates an appointment for deterministic date-classification tests.
Appointment appointment({
  required String id,
  required DateTime dateTime,
  String status = 'confirmed',
  String vetId = 'vet-001',
}) {
  return Appointment(
    appointmentId: id,
    ownerId: 'owner-001',
    petId: 'pet-001',
    hospitalId: 'hospital-001',
    serviceId: 'service-001',
    vetId: vetId,
    dateTime: dateTime,
    reason: 'Routine consultation',
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('AppointmentDateClassifier.classify', () {
    final now = DateTime(2026, 11, 3, 14, 30);

    test('classifies yesterday as overdue', () {
      final item = appointment(
        id: 'yesterday',
        dateTime: DateTime(2026, 11, 2, 10),
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.overdue,
      );
    });

    test('classifies a pending appointment yesterday as overdue', () {
      final item = appointment(
        id: 'pending-yesterday',
        dateTime: DateTime(2026, 11, 2, 16),
        status: 'pending',
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.overdue,
      );
    });

    test('classifies an earlier appointment today as today', () {
      final item = appointment(
        id: 'earlier-today',
        dateTime: DateTime(2026, 11, 3, 9),
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.today,
      );
    });

    test('classifies a later appointment today as today', () {
      final item = appointment(
        id: 'later-today',
        dateTime: DateTime(2026, 11, 3, 18),
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.today,
      );
    });

    test('classifies tomorrow as tomorrow', () {
      final item = appointment(
        id: 'tomorrow',
        dateTime: DateTime(2026, 11, 4, 9),
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.tomorrow,
      );
    });

    test('classifies next week as upcoming', () {
      final item = appointment(
        id: 'next-week',
        dateTime: DateTime(2026, 11, 10, 11),
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.upcoming,
      );
    });

    test('handles month rollover', () {
      final monthEnd = DateTime(2026, 11, 30, 23, 30);

      final item = appointment(
        id: 'december-first',
        dateTime: DateTime(2026, 12, 1, 8),
      );

      expect(
        AppointmentDateClassifier.classify(item, now: monthEnd),
        AppointmentDateCategory.tomorrow,
      );
    });

    test('handles year rollover', () {
      final yearEnd = DateTime(2026, 12, 31, 23, 30);

      final item = appointment(
        id: 'new-year',
        dateTime: DateTime(2027, 1, 1, 9),
      );

      expect(
        AppointmentDateClassifier.classify(item, now: yearEnd),
        AppointmentDateCategory.tomorrow,
      );
    });

    test('classifies cancelled appointments as history', () {
      final item = appointment(
        id: 'cancelled',
        dateTime: DateTime(2026, 11, 4, 10),
        status: 'cancelled',
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.history,
      );
    });

    test('classifies rejected appointments as history', () {
      final item = appointment(
        id: 'rejected',
        dateTime: DateTime(2026, 11, 4, 10),
        status: 'rejected',
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.history,
      );
    });

    test('classifies completed appointments as history', () {
      final item = appointment(
        id: 'completed',
        dateTime: DateTime(2026, 11, 4, 10),
        status: 'completed',
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.history,
      );
    });

    test('classifies unknown statuses conservatively as history', () {
      final item = appointment(
        id: 'unknown',
        dateTime: DateTime(2026, 11, 4, 10),
        status: 'unexpected_state',
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.history,
      );
    });

    test('normalizes whitespace and case in appointment status', () {
      final item = appointment(
        id: 'mixed-case',
        dateTime: DateTime(2026, 11, 4, 10),
        status: ' Confirmed ',
      );

      expect(
        AppointmentDateClassifier.classify(item, now: now),
        AppointmentDateCategory.tomorrow,
      );
    });

    test('handles UTC timestamps as local calendar dates', () {
      final item = appointment(
        id: 'utc-appointment',
        dateTime: DateTime.utc(2026, 11, 4, 9),
      );

      final localAppointmentTime = item.dateTime.toLocal();
      final localNow = DateTime(
        localAppointmentTime.year,
        localAppointmentTime.month,
        localAppointmentTime.day,
        0,
      );

      expect(
        AppointmentDateClassifier.classify(item, now: localNow),
        AppointmentDateCategory.today,
      );
    });
  });

  group('AppointmentDateClassifier.isActive', () {
    test('accepts pending and confirmed statuses', () {
      for (final status in ['pending', 'confirmed', ' CONFIRMED ']) {
        final item = appointment(
          id: status,
          dateTime: DateTime(2026, 11, 4),
          status: status,
        );

        expect(AppointmentDateClassifier.isActive(item), isTrue);
      }
    });

    test('excludes terminal and unknown statuses', () {
      for (final status in [
        'cancelled',
        'rejected',
        'completed',
        'unexpected_state',
      ]) {
        final item = appointment(
          id: status,
          dateTime: DateTime(2026, 11, 4),
          status: status,
        );

        expect(AppointmentDateClassifier.isActive(item), isFalse);
      }
    });
  });

  group('AppointmentDateClassifier.isConfirmedForVeterinarian', () {
    final now = DateTime(2026, 11, 3, 14);

    test('includes tomorrow confirmed appointments today', () {
      final item = appointment(
        id: 'tomorrow-confirmed',
        dateTime: DateTime(2026, 11, 4, 9),
      );

      expect(
        AppointmentDateClassifier.isConfirmedForVeterinarian(item, now: now),
        isTrue,
      );
    });

    test('includes future confirmed appointments', () {
      final item = appointment(
        id: 'next-week-confirmed',
        dateTime: DateTime(2026, 11, 10, 9),
      );

      expect(
        AppointmentDateClassifier.isConfirmedForVeterinarian(item, now: now),
        isTrue,
      );
    });

    test('includes confirmed appointments earlier today', () {
      final item = appointment(
        id: 'today-confirmed',
        dateTime: DateTime(2026, 11, 3, 8),
      );

      expect(
        AppointmentDateClassifier.isConfirmedForVeterinarian(item, now: now),
        isTrue,
      );
    });

    test('excludes pending appointments from confirmed shortlist', () {
      final item = appointment(
        id: 'tomorrow-pending',
        dateTime: DateTime(2026, 11, 4, 9),
        status: 'pending',
      );

      expect(
        AppointmentDateClassifier.isConfirmedForVeterinarian(item, now: now),
        isFalse,
      );
    });

    test('excludes overdue appointments from upcoming shortlist', () {
      final item = appointment(
        id: 'overdue-confirmed',
        dateTime: DateTime(2026, 11, 2, 9),
      );

      expect(
        AppointmentDateClassifier.isConfirmedForVeterinarian(item, now: now),
        isFalse,
      );
    });

    test('excludes cancelled and rejected appointments', () {
      for (final status in ['cancelled', 'rejected']) {
        final item = appointment(
          id: status,
          dateTime: DateTime(2026, 11, 4, 9),
          status: status,
        );

        expect(
          AppointmentDateClassifier.isConfirmedForVeterinarian(item, now: now),
          isFalse,
        );
      }
    });
  });

  group('AppointmentDateClassifier.activeSorted', () {
    test('sorts active appointments without mutating the input', () {
      final late = appointment(id: 'late', dateTime: DateTime(2026, 11, 5, 15));

      final early = appointment(
        id: 'early',
        dateTime: DateTime(2026, 11, 4, 9),
        status: 'pending',
      );

      final cancelled = appointment(
        id: 'cancelled',
        dateTime: DateTime(2026, 11, 3, 8),
        status: 'cancelled',
      );

      final input = [late, cancelled, early];

      final result = AppointmentDateClassifier.activeSorted(input);

      expect(result.map((item) => item.appointmentId).toList(), [
        'early',
        'late',
      ]);

      expect(input.map((item) => item.appointmentId).toList(), [
        'late',
        'cancelled',
        'early',
      ]);
    });

    test('returns an empty list when no appointments are active', () {
      final input = [
        appointment(
          id: 'cancelled',
          dateTime: DateTime(2026, 11, 4),
          status: 'cancelled',
        ),
        appointment(
          id: 'completed',
          dateTime: DateTime(2026, 11, 5),
          status: 'completed',
        ),
      ];

      final result = AppointmentDateClassifier.activeSorted(input);

      expect(result, isEmpty);
    });
  });
}
