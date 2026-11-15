import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_appointments_page.dart';

class _FakeAppointmentRepository implements AppointmentRepository {
  _FakeAppointmentRepository({required this.appointments});

  List<Appointment> appointments;

  bool failLoading = false;
  bool failConfirmation = false;
  bool failRejection = false;

  int loadCallCount = 0;
  int confirmCallCount = 0;
  int rejectCallCount = 0;

  String? requestedHospitalId;
  String? confirmedAppointmentId;
  String? rejectedAppointmentId;

  @override
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId) async {
    loadCallCount++;
    requestedHospitalId = hospitalId;

    if (failLoading) {
      throw Exception('Simulated loading failure');
    }

    return List<Appointment>.of(appointments);
  }

  @override
  Future<void> confirmAppointment(String appointmentId) async {
    confirmCallCount++;
    confirmedAppointmentId = appointmentId;

    if (failConfirmation) {
      throw Exception('Simulated confirmation failure');
    }
  }

  @override
  Future<void> rejectAppointment(String appointmentId) async {
    rejectCallCount++;
    rejectedAppointmentId = appointmentId;

    if (failRejection) {
      throw Exception('Simulated rejection failure');
    }
  }

  @override
  Future<Appointment> createAppointment(Appointment appointment) async {
    throw UnsupportedError('Not required by this test.');
  }

  @override
  Future<List<Appointment>> getAppointments() async => [];

  @override
  Future<List<Appointment>> getAppointmentsByVeterinarian({
    required String vetId,
    required String hospitalId,
  }) async {
    return [];
  }

  @override
  Future<Appointment?> getAppointmentById(String appointmentId) async {
    return null;
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {}

  @override
  Future<void> cancelAppointment(String appointmentId) async {}
}

Appointment _createAppointment({
  required String id,
  String status = 'pending',
  String hospitalId = 'hospital-001',
  DateTime? dateTime,
}) {
  return Appointment(
    appointmentId: id,
    ownerId: 'owner-001',
    petId: 'pet-001',
    hospitalId: hospitalId,
    serviceId: 'service-001',
    vetId: 'vet-001',
    dateTime: dateTime ?? DateTime(2026, 11, 10, 9),
    reason: 'Routine health checkup',
    status: status,
    createdAt: DateTime(2026, 11, 1),
  );
}

Future<void> _pumpAppointmentsPage(
  WidgetTester tester,
  _FakeAppointmentRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StaffAppointmentsPage(
          hospitalId: 'hospital-001',
          repository: repository,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

/// Scrolls the main vertical list until a lazily-built widget is available.
Future<void> _scrollToText(WidgetTester tester, String text) async {
  final finder = find.text(text);

  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );

  await tester.pumpAndSettle();
}

void main() {
  group('StaffAppointmentsPage', () {
    testWidgets('excludes appointments from another hospital', (tester) async {
      final repository = _FakeAppointmentRepository(
        appointments: [
          _createAppointment(id: 'ours001'),
          _createAppointment(id: 'other001', hospitalId: 'hospital-002'),
        ],
      );

      await _pumpAppointmentsPage(tester, repository);

      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Appointment #other001'), findsNothing);
      await _scrollToText(tester, 'Appointment #ours001');
      expect(find.text('Appointment #ours001'), findsOneWidget);
    });

    testWidgets('loads appointments for the assigned hospital', (tester) async {
      final repository = _FakeAppointmentRepository(
        appointments: [_createAppointment(id: 'appt001')],
      );

      await _pumpAppointmentsPage(tester, repository);

      expect(repository.loadCallCount, 1);
      expect(repository.requestedHospitalId, 'hospital-001');

      expect(find.text('Hospital Appointments'), findsOneWidget);
      expect(find.text('Hospital ID: hospital-001'), findsOneWidget);

      await _scrollToText(tester, 'Appointment #appt001');

      expect(find.text('Appointment #appt001'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('displays an empty state when no appointments exist', (
      tester,
    ) async {
      final repository = _FakeAppointmentRepository(appointments: []);

      await _pumpAppointmentsPage(tester, repository);

      expect(find.text('No appointments found'), findsOneWidget);
      expect(
        find.text('Appointments for your hospital will appear here.'),
        findsOneWidget,
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('filters appointments by confirmed status', (tester) async {
      final repository = _FakeAppointmentRepository(
        appointments: [
          _createAppointment(id: 'pend001', status: 'pending'),
          _createAppointment(id: 'conf001', status: 'confirmed'),
        ],
      );

      await _pumpAppointmentsPage(tester, repository);

      final confirmedFilter = find.text('Confirmed (1)');

      await tester.ensureVisible(confirmedFilter);
      await tester.tap(confirmedFilter);
      await tester.pumpAndSettle();

      await _scrollToText(tester, 'Appointment #conf001');

      expect(find.text('Appointment #conf001'), findsOneWidget);
      expect(find.text('Appointment #pend001'), findsNothing);
    });

    testWidgets('filters appointments by rejected status', (tester) async {
      final repository = _FakeAppointmentRepository(
        appointments: [
          _createAppointment(id: 'pend001', status: 'pending'),
          _createAppointment(id: 'rej001', status: 'rejected'),
        ],
      );

      await _pumpAppointmentsPage(tester, repository);

      final rejectedFilter = find.text('Rejected (1)');

      await tester.ensureVisible(rejectedFilter);
      await tester.tap(rejectedFilter);
      await tester.pumpAndSettle();

      await _scrollToText(tester, 'Appointment #rej001');

      expect(find.text('Appointment #rej001'), findsOneWidget);
      expect(find.text('Appointment #pend001'), findsNothing);
    });

    testWidgets('confirms a pending appointment successfully', (tester) async {
      final repository = _FakeAppointmentRepository(
        appointments: [_createAppointment(id: 'cnfrm01')],
      );

      await _pumpAppointmentsPage(tester, repository);

      final confirmButton = find.widgetWithText(FilledButton, 'Confirm');

      await tester.ensureVisible(confirmButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(repository.confirmCallCount, 1);
      expect(repository.confirmedAppointmentId, 'cnfrm01');

      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('PENDING'), findsNothing);
      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Reject'), findsNothing);

      expect(find.text('Appointment confirmed successfully.'), findsOneWidget);
    });

    testWidgets('rejects a pending appointment after confirmation dialog', (
      tester,
    ) async {
      final repository = _FakeAppointmentRepository(
        appointments: [_createAppointment(id: 'reject01')],
      );

      await _pumpAppointmentsPage(tester, repository);

      final rejectButton = find.widgetWithText(OutlinedButton, 'Reject');

      await tester.ensureVisible(rejectButton);
      await tester.pumpAndSettle();
      await tester.tap(rejectButton);
      await tester.pumpAndSettle();

      expect(find.text('Reject appointment?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
      await tester.pumpAndSettle();

      expect(repository.rejectCallCount, 1);
      expect(repository.rejectedAppointmentId, 'reject01');

      expect(find.text('REJECTED'), findsOneWidget);
      expect(find.text('PENDING'), findsNothing);

      expect(find.text('Appointment rejected successfully.'), findsOneWidget);
    });

    testWidgets('does not reject when the user cancels the dialog', (
      tester,
    ) async {
      final repository = _FakeAppointmentRepository(
        appointments: [_createAppointment(id: 'cancel01')],
      );

      await _pumpAppointmentsPage(tester, repository);

      final rejectButton = find.widgetWithText(OutlinedButton, 'Reject');

      await tester.ensureVisible(rejectButton);
      await tester.pumpAndSettle();
      await tester.tap(rejectButton);
      await tester.pumpAndSettle();

      expect(find.text('Reject appointment?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(repository.rejectCallCount, 0);
      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('shows retry state when appointment loading fails', (
      tester,
    ) async {
      final repository = _FakeAppointmentRepository(
        appointments: [_createAppointment(id: 'retry01')],
      )..failLoading = true;

      await _pumpAppointmentsPage(tester, repository);

      expect(
        find.text('Unable to load hospital appointments. Please try again.'),
        findsOneWidget,
      );

      expect(find.text('Try Again'), findsOneWidget);

      repository.failLoading = false;

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(repository.loadCallCount, 2);

      await _scrollToText(tester, 'Appointment #retry01');

      expect(find.text('Appointment #retry01'), findsOneWidget);
    });

    testWidgets('keeps appointment pending when confirmation fails', (
      tester,
    ) async {
      final repository = _FakeAppointmentRepository(
        appointments: [_createAppointment(id: 'fail001')],
      )..failConfirmation = true;

      await _pumpAppointmentsPage(tester, repository);

      final confirmButton = find.widgetWithText(FilledButton, 'Confirm');

      await tester.ensureVisible(confirmButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(repository.confirmCallCount, 1);

      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsNothing);

      expect(
        find.text(
          'Unable to confirm this appointment. '
          'Please refresh and try again.',
        ),
        findsOneWidget,
      );

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });
  });
}
