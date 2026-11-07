import '../entities/hospital_staff_assignment.dart';

/// Defines how the application retrieves the current user's hospital
/// staff assignment.
///
/// Implementations must only expose the assignment belonging to the
/// currently authenticated user.
abstract interface class HospitalStaffAssignmentRepository {
  /// Continuously observes the current user's hospital assignment.
  ///
  /// Returns `null` when:
  /// - No authenticated user exists.
  /// - The user's assignment document does not exist.
  ///
  /// Firestore or network failures should be emitted as stream errors.
  Stream<HospitalStaffAssignment?> watchCurrentAssignment();
}
