import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/hospital_staff/domain/entities/hospital_staff_assignment.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_shell_page.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';

class _FakeHospitalRepository implements HospitalRepository {
  int callCount = 0;
  final List<String> requestedHospitalIds = [];

  @override
  Future<Hospital?> getHospitalById(String hospitalId) async {
    callCount++;
    requestedHospitalIds.add(hospitalId);

    return const Hospital(
      hospitalId: 'hospital-001',
      name: 'PetCare Animal Hospital',
      location: 'Colombo, Sri Lanka',
      contact: '0112345678',
      hours: 'Monday - Saturday, 8 AM - 6 PM',
      active: true,
    );
  }

  @override
  Future<List<Hospital>> getHospitals() async => [];
}

void main() {
  group('StaffShellPage', () {
    const assignment = HospitalStaffAssignment(
      userId: 'staff-001',
      hospitalId: 'hospital-001',
      active: true,
    );

    testWidgets('displays the assigned hospital overview and navigation', (
      tester,
    ) async {
      final repository = _FakeHospitalRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: StaffShellPage(
            assignment: assignment,
            hospitalRepository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hospital Workspace'), findsOneWidget);
      expect(find.text('PetCare Animal Hospital'), findsOneWidget);
      expect(find.text('Colombo, Sri Lanka'), findsOneWidget);
      expect(find.text('0112345678'), findsOneWidget);
      expect(find.text('Monday - Saturday, 8 AM - 6 PM'), findsOneWidget);

      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Appointments'), findsWidgets);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      expect(repository.callCount, 1);
      expect(repository.requestedHospitalIds, ['hospital-001']);
    });

    testWidgets('navigates between all five dashboard sections', (
      tester,
    ) async {
      final repository = _FakeHospitalRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: StaffShellPage(
            assignment: assignment,
            hospitalRepository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Appointments
      await tester.tap(find.text('Appointments').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Appointments'), findsOneWidget);
      expect(
        find.text(
          'Review appointment requests, manage confirmations, '
          'and monitor hospital appointments.',
        ),
        findsOneWidget,
      );

      // Daily Schedule
      await tester.tap(find.text('Schedule').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Schedule'), findsOneWidget);
      expect(find.text('Daily Schedule'), findsOneWidget);

      // Queue Management
      await tester.tap(find.text('Queue').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Queue'), findsOneWidget);
      expect(find.text('Queue Management'), findsOneWidget);

      // Profile
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
      expect(find.text('Staff Profile'), findsOneWidget);

      // Return to Overview
      await tester.tap(find.text('Overview').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Overview'), findsOneWidget);
      expect(find.text('Hospital Workspace'), findsOneWidget);

      // IndexedStack should preserve the loaded overview without
      // issuing another repository request.
      expect(repository.callCount, 1);
    });
  });
}
