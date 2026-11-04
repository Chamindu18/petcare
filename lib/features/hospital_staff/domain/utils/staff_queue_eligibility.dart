import '../../../appointments/domain/entities/appointment.dart';

/// Reasons an appointment cannot enter the hospital's daily queue.
enum StaffQueueIneligibilityReason {
  wrongHospital,
  notConfirmed,
  notScheduledToday,
  alreadyCheckedIn,
  invalidAppointment,
}

/// Result of a staff queue eligibility check.
class StaffQueueEligibilityResult {
  const StaffQueueEligibilityResult._({required this.isEligible, this.reason});

  const StaffQueueEligibilityResult.eligible() : this._(isEligible: true);

  const StaffQueueEligibilityResult.ineligible(
    StaffQueueIneligibilityReason reason,
  ) : this._(isEligible: false, reason: reason);

  final bool isEligible;
  final StaffQueueIneligibilityReason? reason;

  /// Human-readable explanation suitable for staff-facing errors.
  String? get message {
    return switch (reason) {
      null => null,
      StaffQueueIneligibilityReason.wrongHospital =>
        'This appointment does not belong to your assigned hospital.',
      StaffQueueIneligibilityReason.notConfirmed =>
        'Only confirmed appointments can be checked in.',
      StaffQueueIneligibilityReason.notScheduledToday =>
        'Only appointments scheduled for today can enter the queue.',
      StaffQueueIneligibilityReason.alreadyCheckedIn =>
        'This appointment has already been added to a queue.',
      StaffQueueIneligibilityReason.invalidAppointment =>
        'The appointment is missing required information.',
    };
  }
}

/// Validates appointment eligibility before hospital staff check-in.
///
/// This is a pure domain utility: it performs no Firebase writes.
///
/// Authorization and duplicate prevention must also be enforced
/// inside the Firestore transaction used for check-in.
class StaffQueueEligibility {
  const StaffQueueEligibility._();

  static StaffQueueEligibilityResult evaluate({
    required Appointment appointment,
    required String assignedHospitalId,
    DateTime? now,
    // Use the backend hospital offset when the device timezone may differ.
    Duration? utcOffset,
  }) {
    final trustedHospitalId = assignedHospitalId.trim();

    if (trustedHospitalId.isEmpty ||
        appointment.hospitalId != trustedHospitalId) {
      return const StaffQueueEligibilityResult.ineligible(
        StaffQueueIneligibilityReason.wrongHospital,
      );
    }

    if (appointment.appointmentId.trim().isEmpty ||
        appointment.ownerId.trim().isEmpty ||
        appointment.petId.trim().isEmpty ||
        appointment.vetId.trim().isEmpty) {
      return const StaffQueueEligibilityResult.ineligible(
        StaffQueueIneligibilityReason.invalidAppointment,
      );
    }

    if (appointment.status.trim().toLowerCase() != 'confirmed') {
      return const StaffQueueEligibilityResult.ineligible(
        StaffQueueIneligibilityReason.notConfirmed,
      );
    }

    if (appointment.queueId?.trim().isNotEmpty == true) {
      return const StaffQueueEligibilityResult.ineligible(
        StaffQueueIneligibilityReason.alreadyCheckedIn,
      );
    }

    final current = utcOffset == null
        ? (now ?? DateTime.now()).toLocal()
        : (now ?? DateTime.now()).toUtc().add(utcOffset);
    final scheduled = utcOffset == null
        ? appointment.dateTime.toLocal()
        : appointment.dateTime.toUtc().add(utcOffset);

    final isToday =
        current.year == scheduled.year &&
        current.month == scheduled.month &&
        current.day == scheduled.day;

    if (!isToday) {
      return const StaffQueueEligibilityResult.ineligible(
        StaffQueueIneligibilityReason.notScheduledToday,
      );
    }

    return const StaffQueueEligibilityResult.eligible();
  }
}
