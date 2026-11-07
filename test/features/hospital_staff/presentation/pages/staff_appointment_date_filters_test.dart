import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_appointments_page.dart';

class _FakeAppointmentRepository implements AppointmentRepository {
  _FakeAppointmentRepository(this.appointments);

  final List<Appointment> appointments;

  int loadCount = 0;
  String? requestedHospitalId;

  @override
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId) async {
    loadCount++;
    requestedHospitalId = hospitalId;
    return List<Appointment>.of(appointments);
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

Appointment _appointment({
  required String id,
  required DateTime scheduledAt,
  String status = 'confirmed',
}) {
  return Appointment(
    appointmentId: id,
    ownerId: 'owner-001',
    petId: 'pet-001',
    hospitalId: 'hospital-001',
    serviceId: 'service-001',
    vetId: 'vet-001',
    dateTime: scheduledAt,
    reason: 'Routine consultation',
    status: status,
    createdAt: scheduledAt.subtract(const Duration(days: 7)),
  );
}

class _AppointmentFixtures {
  _AppointmentFixtures() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    appointments = [
      _appointment(
        id: 'overdue1',
        scheduledAt: DateTime(today.year, today.month, today.day - 1, 10),
        status: 'pending',
      ),
      _appointment(
        id: 'today001',
        scheduledAt: DateTime(today.year, today.month, today.day, 9),
      ),
      _appointment(
        id: 'tomorr01',
        scheduledAt: DateTime(today.year, today.month, today.day + 1, 9),
      ),
      _appointment(
        id: 'tomorr02',
        scheduledAt: DateTime(today.year, today.month, today.day + 1, 11),
        status: 'pending',
      ),
      _appointment(
        id: 'future01',
        scheduledAt: DateTime(today.year, today.month, today.day + 7, 14),
      ),
      _appointment(
        id: 'cancel01',
        scheduledAt: DateTime(today.year, today.month, today.day + 1, 15),
        status: 'cancelled',
      ),
    ];
  }

  late final List<Appointment> appointments;
}

Future<void> _pumpPage(
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

/// Returns the main vertical appointment list to its beginning.
///
/// This ensures filter controls can be located even after a previous
/// interaction scrolls the list to an appointment card.
Future<void> _scrollToTop(WidgetTester tester) async {
  final verticalScrollable = find.byType(Scrollable).first;

  final state = tester.state<ScrollableState>(verticalScrollable);

  state.position.jumpTo(0);
  await tester.pumpAndSettle();
}

/// Selects a status or date chip, handling both vertical and horizontal
/// scrolling before tapping the control.
Future<void> _selectFilter(WidgetTester tester, String label) async {
  await _scrollToTop(tester);

  final target = find.text(label);
  final verticalScrollable = find.byType(Scrollable).first;

  await tester.scrollUntilVisible(
    target,
    150,
    scrollable: verticalScrollable,
    maxScrolls: 20,
  );

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();

  expect(target, findsOneWidget);

  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Locates an appointment card using the eight-character ID displayed
/// by the production appointment UI.
Future<void> _scrollToAppointment(
  WidgetTester tester,
  String appointmentId,
) async {
  final target = find.text('Appointment #$appointmentId');

  await tester.scrollUntilVisible(
    target,
    150,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 30,
  );

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();

  expect(target, findsOneWidget);
}

void main() {
  group('Staff Appointments date filters', () {
    testWidgets(
      'shows overdue appointments separately from future appointments',
      (tester) async {
        final fixtures = _AppointmentFixtures();
        final repository = _FakeAppointmentRepository(fixtures.appointments);

        await _pumpPage(tester, repository);

        expect(repository.loadCount, 1);
        expect(repository.requestedHospitalId, 'hospital-001');

        await _selectFilter(tester, 'Overdue (1)');

        await _scrollToAppointment(tester, 'overdue1');

        expect(find.text('Appointment #tomorr01'), findsNothing);

        expect(find.text('Appointment #today001'), findsNothing);
      },
    );

    testWidgets('shows appointments scheduled for today', (tester) async {
      final fixtures = _AppointmentFixtures();

      await _pumpPage(
        tester,
        _FakeAppointmentRepository(fixtures.appointments),
      );

      await _selectFilter(tester, 'Today (1)');

      await _scrollToAppointment(tester, 'today001');

      expect(find.text('Appointment #overdue1'), findsNothing);

      expect(find.text('Appointment #tomorr01'), findsNothing);
    });

    testWidgets('shows tomorrow appointments before their scheduled day', (
      tester,
    ) async {
      final fixtures = _AppointmentFixtures();

      await _pumpPage(
        tester,
        _FakeAppointmentRepository(fixtures.appointments),
      );

      await _selectFilter(tester, 'Tomorrow (2)');

      await _scrollToAppointment(tester, 'tomorr01');
      await _scrollToAppointment(tester, 'tomorr02');

      expect(find.text('Appointment #future01'), findsNothing);
    });

    testWidgets('Upcoming includes tomorrow and later appointments', (
      tester,
    ) async {
      final fixtures = _AppointmentFixtures();

      await _pumpPage(
        tester,
        _FakeAppointmentRepository(fixtures.appointments),
      );

      await _selectFilter(tester, 'Upcoming (3)');

      await _scrollToAppointment(tester, 'tomorr01');
      await _scrollToAppointment(tester, 'future01');

      expect(find.text('Appointment #overdue1'), findsNothing);

      expect(find.text('Appointment #cancel01'), findsNothing);
    });

    testWidgets('combines Confirmed status with Tomorrow date filter', (
      tester,
    ) async {
      final fixtures = _AppointmentFixtures();

      await _pumpPage(
        tester,
        _FakeAppointmentRepository(fixtures.appointments),
      );

      await _selectFilter(tester, 'Tomorrow (2)');

      // Counts respond to the currently selected date period.
      await _selectFilter(tester, 'Confirmed (1)');

      await _scrollToAppointment(tester, 'tomorr01');

      expect(find.text('Appointment #tomorr02'), findsNothing);

      expect(find.text('Appointment #future01'), findsNothing);
    });

    testWidgets('places cancelled appointments in History', (tester) async {
      final fixtures = _AppointmentFixtures();

      await _pumpPage(
        tester,
        _FakeAppointmentRepository(fixtures.appointments),
      );

      await _selectFilter(tester, 'History (1)');

      await _scrollToAppointment(tester, 'cancel01');

      expect(find.text('Appointment #tomorr01'), findsNothing);
    });
  });
}
