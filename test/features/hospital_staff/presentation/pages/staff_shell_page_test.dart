import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
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

class _FakeAppointmentRepository implements AppointmentRepository {
  int hospitalAppointmentCallCount = 0;
  final List<String> requestedHospitalIds = [];

  @override
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId) async {
    hospitalAppointmentCallCount++;
    requestedHospitalIds.add(hospitalId);

    return [];
  }

  @override
  Future<Appointment> createAppointment(Appointment appointment) {
    throw UnsupportedError('Not required by this test.');
  }

  @override
  Future<List<Appointment>> getAppointments() async => [];

  @override
  Future<List<Appointment>> getAppointmentsByVeterinarian({
    required String vetId,
    required String hospitalId,
  }) async => [];

  @override
  Future<Appointment?> getAppointmentById(String appointmentId) async => null;

  @override
  Future<void> updateAppointment(Appointment appointment) async {}

  @override
  Future<void> cancelAppointment(String appointmentId) async {}

  @override
  Future<void> confirmAppointment(String appointmentId) async {}

  @override
  Future<void> rejectAppointment(String appointmentId) async {}
}

void main() {
  group('StaffShellPage', () {
    const assignment = HospitalStaffAssignment(
      userId: 'staff-001',
      hospitalId: 'hospital-001',
      active: true,
    );

    testWidgets('displays the operational overview and all navigation tabs', (
      tester,
    ) async {
      final hospitalRepository = _FakeHospitalRepository();
      final appointmentRepository = _FakeAppointmentRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: StaffShellPage(
            assignment: assignment,
            hospitalRepository: hospitalRepository,
            appointmentRepository: appointmentRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hospital Workspace'), findsOneWidget);
      expect(find.text('PetCare Animal Hospital'), findsOneWidget);

      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Appointments'), findsWidgets);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      expect(hospitalRepository.callCount, 1);
      expect(hospitalRepository.requestedHospitalIds, ['hospital-001']);

      // Overview and Appointments each load hospital-scoped data.
      expect(appointmentRepository.hospitalAppointmentCallCount, 2);

      expect(appointmentRepository.requestedHospitalIds, [
        'hospital-001',
        'hospital-001',
      ]);

      // Appointment statistics must be available on Overview.
      expect(find.text('Appointment Overview'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Total Appointments'), findsOneWidget);
    });

    testWidgets('navigates between all five dashboard sections', (
      tester,
    ) async {
      final hospitalRepository = _FakeHospitalRepository();
      final appointmentRepository = _FakeAppointmentRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: StaffShellPage(
            assignment: assignment,
            hospitalRepository: hospitalRepository,
            appointmentRepository: appointmentRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Appointments
      await tester.tap(find.text('Appointments').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Appointments'), findsOneWidget);
      expect(find.text('Hospital Appointments'), findsOneWidget);
      expect(find.text('No appointments found'), findsOneWidget);
      expect(find.text('Hospital ID: hospital-001'), findsOneWidget);

      // Both Overview and Appointments read the assigned hospital only.
      expect(appointmentRepository.hospitalAppointmentCallCount, 2);
      expect(appointmentRepository.requestedHospitalIds, [
        'hospital-001',
        'hospital-001',
      ]);

      // Schedule
      await tester.tap(find.text('Schedule').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Schedule'), findsOneWidget);
      expect(find.text('Daily Schedule'), findsOneWidget);

      // Queue
      await tester.tap(find.text('Queue').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Queue'), findsOneWidget);
      expect(find.text('Queue Management'), findsOneWidget);

      // Profile
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
      expect(find.text('Staff Profile'), findsOneWidget);

      // Return to Overview.
      await tester.tap(find.text('Overview').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Overview'), findsOneWidget);
      expect(find.text('Hospital Workspace'), findsOneWidget);

      // Returning to Overview refreshes its hospital and appointment data.
      expect(hospitalRepository.callCount, 2);
      expect(hospitalRepository.requestedHospitalIds, [
        'hospital-001',
        'hospital-001',
      ]);

      expect(appointmentRepository.hospitalAppointmentCallCount, 3);

      expect(appointmentRepository.requestedHospitalIds, [
        'hospital-001',
        'hospital-001',
        'hospital-001',
      ]);
    });

    testWidgets('does not reload Overview when its tab is already selected', (
      tester,
    ) async {
      final hospitalRepository = _FakeHospitalRepository();
      final appointmentRepository = _FakeAppointmentRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: StaffShellPage(
            assignment: assignment,
            hospitalRepository: hospitalRepository,
            appointmentRepository: appointmentRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(hospitalRepository.callCount, 1);
      expect(appointmentRepository.hospitalAppointmentCallCount, 2);

      await tester.tap(find.text('Overview').last);
      await tester.pumpAndSettle();

      expect(hospitalRepository.callCount, 1);
      expect(appointmentRepository.hospitalAppointmentCallCount, 2);
    });
  });
}
