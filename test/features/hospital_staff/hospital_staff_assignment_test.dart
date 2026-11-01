import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/hospital_staff/domain/entities/hospital_staff_assignment.dart';

void main() {
  group('HospitalStaffAssignment', () {
    test('grants access for a valid active assignment', () {
      const assignment = HospitalStaffAssignment(
        userId: 'staff-001',
        hospitalId: 'hospital-001',
        active: true,
      );

      expect(assignment.hasValidHospitalAccess, isTrue);
    });

    test('denies access for an inactive assignment', () {
      const assignment = HospitalStaffAssignment(
        userId: 'staff-001',
        hospitalId: 'hospital-001',
        active: false,
      );

      expect(assignment.hasValidHospitalAccess, isFalse);
    });

    test('denies access when user ID is empty', () {
      const assignment = HospitalStaffAssignment(
        userId: '',
        hospitalId: 'hospital-001',
        active: true,
      );

      expect(assignment.hasValidHospitalAccess, isFalse);
    });

    test('denies access when user ID contains surrounding whitespace', () {
      const assignment = HospitalStaffAssignment(
        userId: ' staff-001 ',
        hospitalId: 'hospital-001',
        active: true,
      );

      expect(assignment.hasValidHospitalAccess, isFalse);
    });

    test('denies access when hospital ID is empty', () {
      const assignment = HospitalStaffAssignment(
        userId: 'staff-001',
        hospitalId: '',
        active: true,
      );

      expect(assignment.hasValidHospitalAccess, isFalse);
    });

    test('denies access when hospital ID contains only whitespace', () {
      const assignment = HospitalStaffAssignment(
        userId: 'staff-001',
        hospitalId: '   ',
        active: true,
      );

      expect(assignment.hasValidHospitalAccess, isFalse);
    });

    test('denies access when hospital ID contains surrounding whitespace', () {
      const assignment = HospitalStaffAssignment(
        userId: 'staff-001',
        hospitalId: ' hospital-001 ',
        active: true,
      );

      expect(assignment.hasValidHospitalAccess, isFalse);
    });

    test('denies access for the unassigned hospital placeholder', () {
      const assignment = HospitalStaffAssignment(
        userId: 'staff-001',
        hospitalId: 'unassigned',
        active: true,
      );

      expect(assignment.hasValidHospitalAccess, isFalse);
    });
  });
}
