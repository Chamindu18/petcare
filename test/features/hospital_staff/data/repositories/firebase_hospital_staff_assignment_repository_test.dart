import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/hospital_staff/data/repositories/firebase_hospital_staff_assignment_repository.dart';

void main() {
  group('FirebaseHospitalStaffAssignmentRepository', () {
    test('returns null when no user is authenticated', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: false);

      final repository = FirebaseHospitalStaffAssignmentRepository(
        auth: auth,
        firestore: firestore,
      );

      final assignment = await repository.watchCurrentAssignment().first;

      expect(assignment, isNull);
    });

    test('returns the current authenticated user assignment', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'staff-001'),
      );

      await firestore.collection('hospital_staff').doc('staff-001').set({
        'userId': 'staff-001',
        'hospitalId': 'hospital-001',
        'active': true,
      });

      final repository = FirebaseHospitalStaffAssignmentRepository(
        auth: auth,
        firestore: firestore,
      );

      final assignment = await repository.watchCurrentAssignment().first;

      expect(assignment, isNotNull);
      expect(assignment!.userId, 'staff-001');
      expect(assignment.hospitalId, 'hospital-001');
      expect(assignment.active, isTrue);
      expect(assignment.hasValidHospitalAccess, isTrue);
    });

    test('returns null when the assignment document does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'staff-001'),
      );

      final repository = FirebaseHospitalStaffAssignmentRepository(
        auth: auth,
        firestore: firestore,
      );

      final assignment = await repository.watchCurrentAssignment().first;

      expect(assignment, isNull);
    });

    test('does not return another users assignment', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'staff-001'),
      );

      await firestore.collection('hospital_staff').doc('staff-001').set({
        'userId': 'staff-002',
        'hospitalId': 'hospital-001',
        'active': true,
      });

      final repository = FirebaseHospitalStaffAssignmentRepository(
        auth: auth,
        firestore: firestore,
      );

      final assignment = await repository.watchCurrentAssignment().first;

      expect(assignment, isNull);
    });

    test('returns null when the userId field is missing', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'staff-001'),
      );

      await firestore.collection('hospital_staff').doc('staff-001').set({
        'hospitalId': 'hospital-001',
        'active': true,
      });

      final repository = FirebaseHospitalStaffAssignmentRepository(
        auth: auth,
        firestore: firestore,
      );

      final assignment = await repository.watchCurrentAssignment().first;

      expect(assignment, isNull);
    });

    test('returns null when hospitalId has an invalid type', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'staff-001'),
      );

      await firestore.collection('hospital_staff').doc('staff-001').set({
        'userId': 'staff-001',
        'hospitalId': 123,
        'active': true,
      });

      final repository = FirebaseHospitalStaffAssignmentRepository(
        auth: auth,
        firestore: firestore,
      );

      final assignment = await repository.watchCurrentAssignment().first;

      expect(assignment, isNull);
    });

    test('returns null when active has an invalid type', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'staff-001'),
      );

      await firestore.collection('hospital_staff').doc('staff-001').set({
        'userId': 'staff-001',
        'hospitalId': 'hospital-001',
        'active': 'true',
      });

      final repository = FirebaseHospitalStaffAssignmentRepository(
        auth: auth,
        firestore: firestore,
      );

      final assignment = await repository.watchCurrentAssignment().first;

      expect(assignment, isNull);
    });

    test('returns an inactive assignment without granting access', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'staff-001'),
      );

      await firestore.collection('hospital_staff').doc('staff-001').set({
        'userId': 'staff-001',
        'hospitalId': 'hospital-001',
        'active': false,
      });

      final repository = FirebaseHospitalStaffAssignmentRepository(
        auth: auth,
        firestore: firestore,
      );

      final assignment = await repository.watchCurrentAssignment().first;

      expect(assignment, isNotNull);
      expect(assignment!.active, isFalse);
      expect(assignment.hasValidHospitalAccess, isFalse);
    });
  });
}
