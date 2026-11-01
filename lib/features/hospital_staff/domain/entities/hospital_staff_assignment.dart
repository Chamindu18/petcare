/// Represents the hospital assignment of an authenticated veterinary staff
/// account.
///
/// Assignments must be provisioned through trusted administration.
/// Staff members must never be allowed to change their own assignment.
class HospitalStaffAssignment {
  const HospitalStaffAssignment({
    required this.userId,
    required this.hospitalId,
    required this.active,
  });

  /// Firebase Authentication UID of the assigned staff member.
  final String userId;

  /// ID of the hospital to which the staff member is assigned.
  final String hospitalId;

  /// Whether the staff assignment is currently active.
  final bool active;

  /// Whether this assignment contains valid data and grants hospital access.
  ///
  /// The Firebase repository separately verifies that [userId] matches
  /// the currently authenticated user's UID.
  bool get hasValidHospitalAccess {
    final normalizedUserId = userId.trim();
    final normalizedHospitalId = hospitalId.trim();

    return active &&
        normalizedUserId.isNotEmpty &&
        normalizedUserId == userId &&
        normalizedHospitalId.isNotEmpty &&
        normalizedHospitalId == hospitalId &&
        normalizedHospitalId != 'unassigned';
  }
}
