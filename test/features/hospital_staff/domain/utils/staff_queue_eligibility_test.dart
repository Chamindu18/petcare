import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/hospital_staff/domain/utils/staff_queue_eligibility.dart';

const _hospitalId = 'hospital-001';

/// Creates a valid appointment unless a particular field is overridden.
Appointment _appointment({
  String appointmentId = 'appointment-001',
  String ownerId = 'owner-001',
  String petId = 'pet-001',
  String hospitalId = _hospitalId,
  String vetId = 'vet-001',
  String status = 'confirmed',
  String? queueId,
  DateTime? dateTime,
}) {
  return Appointment(
    appointmentId: appointmentId,
    ownerId: ownerId,
    petId: petId,
    hospitalId: hospitalId,
    serviceId: 'service-001',
    vetId: vetId,
    dateTime: dateTime ?? DateTime(2026, 11, 3, 10),
    reason: 'Routine consultation',
    status: status,
    queueId: queueId,
    createdAt: DateTime(2026, 11, 1, 9),
  );
}

void main() {
  group('StaffQueueEligibility', () {
    final now = DateTime(2026, 11, 3, 9, 30);

    StaffQueueEligibilityResult check(
      Appointment appointment, {
      String assignedHospitalId = _hospitalId,
      DateTime? currentTime,
    }) {
      return StaffQueueEligibility.evaluate(
        appointment: appointment,
        assignedHospitalId: assignedHospitalId,
        now: currentTime ?? now,
      );
    }

    test('allows a confirmed appointment scheduled for today', () {
      final result = check(_appointment());

      expect(result.isEligible, isTrue);
      expect(result.reason, isNull);
      expect(result.message, isNull);
    });

    test('allows a confirmed appointment earlier today', () {
      final result = check(_appointment(dateTime: DateTime(2026, 11, 3, 8)));

      expect(result.isEligible, isTrue);
    });

    test('rejects an appointment belonging to another hospital', () {
      final result = check(_appointment(hospitalId: 'hospital-002'));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.wrongHospital);
      expect(
        result.message,
        'This appointment does not belong to your assigned hospital.',
      );
    });

    test('rejects a missing trusted hospital assignment', () {
      final result = check(_appointment(), assignedHospitalId: '   ');

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.wrongHospital);
    });

    test('rejects pending appointments', () {
      final result = check(_appointment(status: 'pending'));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.notConfirmed);
      expect(result.message, 'Only confirmed appointments can be checked in.');
    });

    test('rejects cancelled, rejected and completed appointments', () {
      for (final status in ['cancelled', 'rejected', 'completed']) {
        final result = check(_appointment(status: status));

        expect(
          result.isEligible,
          isFalse,
          reason: 'Status "$status" must not enter the queue.',
        );

        expect(result.reason, StaffQueueIneligibilityReason.notConfirmed);
      }
    });

    test('normalizes confirmed status whitespace and case', () {
      final result = check(_appointment(status: ' CONFIRMED '));

      expect(result.isEligible, isTrue);
    });

    test('rejects appointments already linked to a queue', () {
      final result = check(_appointment(queueId: 'queue-001'));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.alreadyCheckedIn);
      expect(
        result.message,
        'This appointment has already been added to a queue.',
      );
    });

    test('rejects an appointment scheduled yesterday', () {
      final result = check(_appointment(dateTime: DateTime(2026, 11, 2, 10)));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.notScheduledToday);
    });

    test('rejects an appointment scheduled tomorrow', () {
      final result = check(_appointment(dateTime: DateTime(2026, 11, 4, 10)));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.notScheduledToday);
      expect(
        result.message,
        'Only appointments scheduled for today can enter the queue.',
      );
    });

    test('supports check-in across a month boundary', () {
      final result = check(
        _appointment(dateTime: DateTime(2026, 12, 1, 10)),
        currentTime: DateTime(2026, 12, 1, 9),
      );

      expect(result.isEligible, isTrue);
    });

    test('supports check-in across a year boundary', () {
      final result = check(
        _appointment(dateTime: DateTime(2027, 1, 1, 10)),
        currentTime: DateTime(2027, 1, 1, 9),
      );

      expect(result.isEligible, isTrue);
    });

    test('rejects missing appointment identity', () {
      final result = check(_appointment(appointmentId: '  '));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.invalidAppointment);
    });

    test('rejects missing owner identity', () {
      final result = check(_appointment(ownerId: ''));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.invalidAppointment);
    });

    test('rejects missing pet identity', () {
      final result = check(_appointment(petId: '  '));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.invalidAppointment);
    });

    test('rejects missing veterinarian identity', () {
      final result = check(_appointment(vetId: ''));

      expect(result.isEligible, isFalse);
      expect(result.reason, StaffQueueIneligibilityReason.invalidAppointment);
    });

    test('does not mutate the appointment during validation', () {
      final original = _appointment(
        appointmentId: 'immutable-001',
        status: 'confirmed',
      );

      final result = check(original);

      expect(result.isEligible, isTrue);
      expect(original.appointmentId, 'immutable-001');
      expect(original.status, 'confirmed');
      expect(original.queueId, isNull);
      expect(original.hospitalId, _hospitalId);
    });
  });
}
