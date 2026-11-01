import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/hospital_staff_assignment.dart';
import '../../domain/repositories/hospital_staff_assignment_repository.dart';

/// Firebase implementation of the hospital staff assignment repository.
///
/// A staff member can only retrieve their own assignment. The assignment
/// itself must be provisioned through a trusted administrative process.
class FirebaseHospitalStaffAssignmentRepository
    implements HospitalStaffAssignmentRepository {
  FirebaseHospitalStaffAssignmentRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<HospitalStaffAssignment?> watchCurrentAssignment() {
    final uid = _auth.currentUser?.uid;

    // No authenticated user means there is no staff assignment to load.
    if (uid == null || uid.isEmpty) {
      return Stream.value(null);
    }

    return _firestore.collection('hospital_staff').doc(uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      final userId = data['userId'];
      final hospitalId = data['hospitalId'];
      final active = data['active'];

      // Reject malformed documents and assignments belonging to another
      // user. Never infer access from missing or incorrectly typed fields.
      if (userId is! String ||
          userId != uid ||
          hospitalId is! String ||
          hospitalId.trim().isEmpty ||
          active is! bool) {
        return null;
      }

      return HospitalStaffAssignment(
        userId: userId,
        hospitalId: hospitalId,
        active: active,
      );
    });
  }
}
