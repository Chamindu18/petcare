import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/hospital_staff/domain/entities/hospital_staff_assignment.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_profile_page.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_shell_page.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';

const _assignment = HospitalStaffAssignment(
  userId: 'staff-001',
  hospitalId: 'hospital-001',
  active: true,
);

const _hospital = Hospital(
  hospitalId: 'hospital-001',
  name: 'PetCare Animal Hospital',
  location: 'Colombo, Sri Lanka',
  contact: '0112345678',
  hours: 'Monday - Saturday, 8 AM - 6 PM',
  active: true,
);

const _profile = UserProfile(
  uid: 'staff-001',
  fullName: 'Test Staff Member',
  displayName: 'Test Staff Member',
  email: 'staff@example.com',
  phone: '0771234567',
  role: 'veterinary_staff',
  notificationEnabled: true,
);

class _FakeHospitalRepository implements HospitalRepository {
  int callCount = 0;

  final List<String> requestedHospitalIds = [];

  @override
  Future<Hospital?> getHospitalById(String hospitalId) async {
    callCount++;
    requestedHospitalIds.add(hospitalId);

    return _hospital;
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

class _FakeProfileRepository implements ProfileRepository {
  int watchCount = 0;
  int updateCount = 0;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    watchCount++;

    return Stream<UserProfile?>.value(_profile);
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    updateCount++;
  }

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {
    updateCount++;
  }
}

class _FakeAuthRepository implements AuthRepository {
  int signOutCount = 0;

  @override
  Future<void> signOut() async {
    signOutCount++;
  }

  @override
  Future<void> registerOwner({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithGoogle() async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    throw UnimplementedError();
  }
}

class _TestRepositories {
  final hospital = _FakeHospitalRepository();
  final appointments = _FakeAppointmentRepository();
  final profile = _FakeProfileRepository();
  final auth = _FakeAuthRepository();
}

/// Mounts the staff shell without accessing live Firebase data.
Future<void> _pumpShell(
  WidgetTester tester,
  _TestRepositories repositories,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StaffShellPage(
        assignment: _assignment,
        hospitalRepository: repositories.hospital,
        appointmentRepository: repositories.appointments,
        profileRepository: repositories.profile,
        authRepository: repositories.auth,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

/// Navigates using the bottom navigation bar.
Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Finds content that may be below the visible portion of the
/// active page's lazily built ListView.
Future<void> _scrollToText(WidgetTester tester, String label) async {
  final target = find.text(label);

  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 30,
  );

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  group('StaffShellPage', () {
    testWidgets('displays the operational overview and all five tabs', (
      tester,
    ) async {
      final repositories = _TestRepositories();

      await _pumpShell(tester, repositories);

      expect(find.text('Hospital Workspace'), findsOneWidget);
      expect(find.text('PetCare Animal Hospital'), findsOneWidget);

      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Appointments'), findsWidgets);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      expect(find.text('Appointment Overview'), findsOneWidget);

      expect(repositories.hospital.callCount, 1);
      expect(repositories.hospital.requestedHospitalIds, ['hospital-001']);

      expect(repositories.appointments.hospitalAppointmentCallCount, 2);
      expect(repositories.appointments.requestedHospitalIds, [
        'hospital-001',
        'hospital-001',
      ]);

      expect(repositories.profile.watchCount, 0);
      expect(repositories.profile.updateCount, 0);
      expect(repositories.auth.signOutCount, 0);
    });

    testWidgets('navigates between all five dashboard sections', (
      tester,
    ) async {
      final repositories = _TestRepositories();

      await _pumpShell(tester, repositories);

      // Appointments
      await _selectTab(tester, 'Appointments');

      expect(find.widgetWithText(AppBar, 'Appointments'), findsOneWidget);
      expect(find.text('Hospital Appointments'), findsOneWidget);

      // Date and status filters increase the page height.
      // Scroll before checking the lazily built empty-state content.
      await _scrollToText(tester, 'No appointments found');

      expect(find.text('No appointments found'), findsOneWidget);

      expect(repositories.appointments.hospitalAppointmentCallCount, 2);

      // Schedule
      await _selectTab(tester, 'Schedule');

      expect(find.widgetWithText(AppBar, 'Schedule'), findsOneWidget);
      expect(find.text('Daily Schedule'), findsOneWidget);

      // Queue
      await _selectTab(tester, 'Queue');

      expect(find.widgetWithText(AppBar, 'Queue'), findsOneWidget);
      expect(find.text('Queue Management'), findsOneWidget);

      // Profile
      await _selectTab(tester, 'Profile');

      expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
      expect(find.text('Staff Profile'), findsOneWidget);
      expect(find.text('Test Staff Member'), findsOneWidget);
      expect(find.text('staff@example.com'), findsOneWidget);

      expect(repositories.profile.watchCount, 1);
      expect(repositories.hospital.callCount, 2);

      // Returning to Overview refreshes operational data.
      await _selectTab(tester, 'Overview');

      expect(find.widgetWithText(AppBar, 'Overview'), findsOneWidget);
      expect(find.text('Hospital Workspace'), findsOneWidget);

      expect(repositories.hospital.callCount, 3);
      expect(repositories.hospital.requestedHospitalIds, [
        'hospital-001',
        'hospital-001',
        'hospital-001',
      ]);

      expect(repositories.appointments.hospitalAppointmentCallCount, 3);
      expect(repositories.appointments.requestedHospitalIds, [
        'hospital-001',
        'hospital-001',
        'hospital-001',
      ]);

      expect(repositories.profile.watchCount, 1);
      expect(repositories.profile.updateCount, 0);
    });

    testWidgets('lazily initializes Profile only when selected', (
      tester,
    ) async {
      final repositories = _TestRepositories();

      await _pumpShell(tester, repositories);

      expect(find.byType(StaffProfilePage), findsNothing);
      expect(repositories.profile.watchCount, 0);

      await _selectTab(tester, 'Appointments');
      await _selectTab(tester, 'Schedule');
      await _selectTab(tester, 'Queue');

      expect(find.byType(StaffProfilePage), findsNothing);
      expect(repositories.profile.watchCount, 0);

      await _selectTab(tester, 'Profile');

      expect(find.byType(StaffProfilePage), findsOneWidget);
      expect(repositories.profile.watchCount, 1);
      expect(repositories.hospital.requestedHospitalIds.last, 'hospital-001');
    });

    testWidgets('preserves Profile state when switching away and back', (
      tester,
    ) async {
      final repositories = _TestRepositories();

      await _pumpShell(tester, repositories);

      await _selectTab(tester, 'Profile');

      expect(repositories.profile.watchCount, 1);
      expect(repositories.hospital.callCount, 2);

      await _selectTab(tester, 'Schedule');
      await _selectTab(tester, 'Profile');

      expect(find.text('Staff Profile'), findsOneWidget);
      expect(find.text('Test Staff Member'), findsOneWidget);

      expect(repositories.profile.watchCount, 1);
      expect(repositories.hospital.callCount, 2);
      expect(repositories.profile.updateCount, 0);
      expect(repositories.auth.signOutCount, 0);
    });

    testWidgets('does not refresh Overview when its tab is already selected', (
      tester,
    ) async {
      final repositories = _TestRepositories();

      await _pumpShell(tester, repositories);

      expect(repositories.hospital.callCount, 1);
      expect(repositories.appointments.hospitalAppointmentCallCount, 2);

      await _selectTab(tester, 'Overview');

      expect(repositories.hospital.callCount, 1);
      expect(repositories.appointments.hospitalAppointmentCallCount, 2);
      expect(repositories.profile.watchCount, 0);
    });
  });
}
