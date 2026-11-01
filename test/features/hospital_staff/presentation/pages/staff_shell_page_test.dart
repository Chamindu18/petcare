import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/hospital_staff/domain/entities/hospital_staff_assignment.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_shell_page.dart';

void main() {
  group('StaffShellPage', () {
    const assignment = HospitalStaffAssignment(
      userId: 'staff-001',
      hospitalId: 'hospital-001',
      active: true,
    );

    testWidgets('displays hospital overview and navigation tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: StaffShellPage(assignment: assignment)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hospital Workspace'), findsOneWidget);
      expect(find.text('hospital-001'), findsOneWidget);

      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Appointments'), findsWidgets);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('navigates between all five dashboard sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: StaffShellPage(assignment: assignment)),
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
    });
  });
}
