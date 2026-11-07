import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_hospital_overview_page.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';

const _hospitalId = 'hospital-001';

class _FakeHospitalRepository implements HospitalRepository {
  @override
  Future<Hospital?> getHospitalById(String hospitalId) async {
    if (hospitalId != _hospitalId) {
      return null;
    }

    return const Hospital(
      hospitalId: _hospitalId,
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
  _FakeAppointmentRepository(this.appointments);

  final List<Appointment> appointments;

  int loadCount = 0;
  String? requestedHospitalId;

  @override
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId) async {
    loadCount++;
    requestedHospitalId = hospitalId;

    // Return the supplied fixtures to verify the Overview's
    // defensive hospital isolation independently of Firestore rules.
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
  String hospitalId = _hospitalId,
}) {
  return Appointment(
    appointmentId: id,
    ownerId: 'owner-001',
    petId: 'pet-001',
    hospitalId: hospitalId,
    serviceId: 'service-001',
    vetId: 'vet-001',
    dateTime: scheduledAt,
    reason: 'Routine consultation',
    status: status,
    createdAt: scheduledAt.subtract(const Duration(days: 7)),
  );
}

/// Returns a local calendar date offset by [days], preserving
/// calendar-day arithmetic across month and year boundaries.
DateTime _onDay(DateTime today, int days, int hour) {
  return DateTime(today.year, today.month, today.day + days, hour);
}

Future<void> _pumpOverview(
  WidgetTester tester,
  _FakeAppointmentRepository repository, {
  VoidCallback? onOpenAppointments,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StaffHospitalOverviewPage(
          hospitalId: _hospitalId,
          repository: _FakeHospitalRepository(),
          appointmentRepository: repository,
          onOpenAppointments: onOpenAppointments,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

/// Finds a widget even when it is initially below the viewport.
///
/// The dashboard uses a lazily built ListView, so find.text()
/// alone may not locate content that is off-screen.
Future<void> _scrollTo(WidgetTester tester, String text) async {
  final target = find.text(text);

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
  group('Staff Overview appointment dates', () {
    testWidgets(
      'shows overdue pending appointments and tomorrow confirmed appointments',
      (tester) async {
        final today = DateTime.now();

        final repository = _FakeAppointmentRepository([
          _appointment(
            id: 'overdue1',
            scheduledAt: _onDay(today, -1, 10),
            status: 'pending',
          ),
          _appointment(id: 'tomorr01', scheduledAt: _onDay(today, 1, 9)),
        ]);

        await _pumpOverview(tester, repository);

        expect(repository.loadCount, 1);
        expect(repository.requestedHospitalId, _hospitalId);

        await _scrollTo(tester, 'Overdue Appointments');
        expect(
          find.text('1 unresolved appointment scheduled before today.'),
          findsOneWidget,
        );

        await _scrollTo(tester, 'Appointment #overdue1');
        expect(find.text('Appointment #overdue1'), findsOneWidget);

        await _scrollTo(tester, 'Upcoming Appointments');
        await _scrollTo(tester, 'Appointment #tomorr01');

        expect(find.text('Appointment #tomorr01'), findsOneWidget);
      },
    );

    testWidgets(
      'shows overdue confirmed appointments without changing their status',
      (tester) async {
        final today = DateTime.now();

        final repository = _FakeAppointmentRepository([
          _appointment(
            id: 'pastconf',
            scheduledAt: _onDay(today, -2, 14),
            status: 'confirmed',
          ),
        ]);

        await _pumpOverview(tester, repository);

        await _scrollTo(tester, 'Overdue Appointments');
        await _scrollTo(tester, 'Appointment #pastconf');

        expect(find.text('Appointment #pastconf'), findsOneWidget);
        expect(repository.appointments.single.status, 'confirmed');

        await _scrollTo(tester, 'No upcoming appointments scheduled.');
        expect(
          find.text('No upcoming appointments scheduled.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'excludes cancelled and rejected appointments from active previews',
      (tester) async {
        final today = DateTime.now();

        final repository = _FakeAppointmentRepository([
          _appointment(
            id: 'cancel01',
            scheduledAt: _onDay(today, -1, 9),
            status: 'cancelled',
          ),
          _appointment(
            id: 'reject01',
            scheduledAt: _onDay(today, 1, 9),
            status: 'rejected',
          ),
        ]);

        await _pumpOverview(tester, repository);

        await _scrollTo(tester, 'No upcoming appointments scheduled.');

        expect(find.text('Overdue Appointments'), findsNothing);
        expect(find.text('Appointment #cancel01'), findsNothing);
        expect(find.text('Appointment #reject01'), findsNothing);
        expect(
          find.text('No upcoming appointments scheduled.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('keeps earlier-today appointments out of the overdue list', (
      tester,
    ) async {
      final now = DateTime.now();

      final repository = _FakeAppointmentRepository([
        _appointment(
          id: 'today001',
          scheduledAt: DateTime(now.year, now.month, now.day),
        ),
        _appointment(id: 'tomorr01', scheduledAt: _onDay(now, 1, 10)),
      ]);

      await _pumpOverview(tester, repository);

      await _scrollTo(tester, 'Upcoming Appointments');

      expect(find.text('Overdue Appointments'), findsNothing);

      await _scrollTo(tester, 'Appointment #tomorr01');
      expect(find.text('Appointment #tomorr01'), findsOneWidget);
    });

    testWidgets('does not show records belonging to another hospital', (
      tester,
    ) async {
      final today = DateTime.now();

      final repository = _FakeAppointmentRepository([
        _appointment(
          id: 'other001',
          scheduledAt: _onDay(today, -1, 10),
          hospitalId: 'hospital-002',
        ),
        _appointment(id: 'correct1', scheduledAt: _onDay(today, 1, 10)),
      ]);

      await _pumpOverview(tester, repository);

      expect(repository.requestedHospitalId, _hospitalId);

      await _scrollTo(tester, 'Upcoming Appointments');
      await _scrollTo(tester, 'Appointment #correct1');

      expect(find.text('Appointment #correct1'), findsOneWidget);
      expect(find.text('Appointment #other001'), findsNothing);
      expect(find.text('Overdue Appointments'), findsNothing);
    });

    testWidgets('View All Overdue opens hospital appointments', (tester) async {
      final today = DateTime.now();
      var navigationCount = 0;

      final repository = _FakeAppointmentRepository([
        _appointment(
          id: 'overdue1',
          scheduledAt: _onDay(today, -1, 10),
          status: 'pending',
        ),
      ]);

      await _pumpOverview(
        tester,
        repository,
        onOpenAppointments: () => navigationCount++,
      );

      await _scrollTo(tester, 'View All Overdue');

      await tester.tap(find.text('View All Overdue'));
      await tester.pumpAndSettle();

      expect(navigationCount, 1);
    });
  });
}
