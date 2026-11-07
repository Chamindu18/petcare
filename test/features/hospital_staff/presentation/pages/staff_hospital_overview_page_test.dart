import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_hospital_overview_page.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';

class _FakeHospitalRepository implements HospitalRepository {
  _FakeHospitalRepository(this._getHospital);

  final Future<Hospital?> Function(String hospitalId, int callNumber)
  _getHospital;

  int callCount = 0;
  final List<String> requestedHospitalIds = [];

  @override
  Future<Hospital?> getHospitalById(String hospitalId) {
    callCount++;
    requestedHospitalIds.add(hospitalId);

    return _getHospital(hospitalId, callCount);
  }

  @override
  Future<List<Hospital>> getHospitals() async => [];
}

class _FakeAppointmentRepository implements AppointmentRepository {
  _FakeAppointmentRepository({this.onLoad});

  final Future<List<Appointment>> Function(String hospitalId, int callNumber)?
  onLoad;

  int callCount = 0;
  final List<String> requestedHospitalIds = [];

  @override
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId) {
    callCount++;
    requestedHospitalIds.add(hospitalId);

    return onLoad?.call(hospitalId, callCount) ?? Future.value(<Appointment>[]);
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

Hospital _testHospital({
  bool active = true,
  String name = 'PetCare Animal Hospital',
}) {
  return Hospital(
    hospitalId: 'hospital-001',
    name: name,
    location: 'Colombo, Sri Lanka',
    contact: '0112345678',
    hours: 'Monday - Saturday, 8 AM - 6 PM',
    active: active,
  );
}

Appointment _testAppointment({
  required String id,
  required String status,
  required DateTime dateTime,
  String hospitalId = 'hospital-001',
  DateTime? updatedAt,
}) {
  return Appointment(
    appointmentId: id,
    ownerId: 'owner-001',
    petId: 'pet-001',
    hospitalId: hospitalId,
    serviceId: 'service-001',
    vetId: 'vet-001',
    dateTime: dateTime,
    reason: 'Routine checkup',
    status: status,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: updatedAt,
  );
}

/// Mounts the staff Overview with injected test repositories.
///
/// The fake repositories avoid real Firebase reads and writes.
Future<void> _pumpOverview(
  WidgetTester tester, {
  required HospitalRepository hospitalRepository,
  required AppointmentRepository appointmentRepository,
  VoidCallback? onOpenAppointments,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StaffHospitalOverviewPage(
          hospitalId: 'hospital-001',
          repository: hospitalRepository,
          appointmentRepository: appointmentRepository,
          onOpenAppointments: onOpenAppointments,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('StaffHospitalOverviewPage', () {
    testWidgets('displays hospital details from the repository', (
      tester,
    ) async {
      final hospitalRepository = _FakeHospitalRepository(
        (hospitalId, _) async => _testHospital(),
      );

      final appointmentRepository = _FakeAppointmentRepository();

      await _pumpOverview(
        tester,
        hospitalRepository: hospitalRepository,
        appointmentRepository: appointmentRepository,
      );

      expect(find.text('Hospital Workspace'), findsOneWidget);
      expect(find.text('PetCare Animal Hospital'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(hospitalRepository.callCount, 1);
      expect(hospitalRepository.requestedHospitalIds, ['hospital-001']);

      expect(appointmentRepository.callCount, 1);
      expect(appointmentRepository.requestedHospitalIds, ['hospital-001']);

      await tester.scrollUntilVisible(find.text('Contact Information'), 200);

      expect(find.text('Colombo, Sri Lanka'), findsOneWidget);
      expect(find.text('0112345678'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Operating Hours'), 150);

      expect(find.text('Monday - Saturday, 8 AM - 6 PM'), findsOneWidget);
    });

    testWidgets('shows unavailable state when hospital is missing', (
      tester,
    ) async {
      final hospitalRepository = _FakeHospitalRepository(
        (hospitalId, _) async => null,
      );

      await _pumpOverview(
        tester,
        hospitalRepository: hospitalRepository,
        appointmentRepository: _FakeAppointmentRepository(),
      );

      expect(find.text('Hospital unavailable'), findsOneWidget);

      expect(find.text('PetCare Animal Hospital'), findsNothing);

      expect(find.text('Check Again'), findsOneWidget);
    });

    testWidgets('does not display inactive hospital information', (
      tester,
    ) async {
      final hospitalRepository = _FakeHospitalRepository(
        (hospitalId, _) async => _testHospital(active: false),
      );

      await _pumpOverview(
        tester,
        hospitalRepository: hospitalRepository,
        appointmentRepository: _FakeAppointmentRepository(),
      );

      expect(find.text('Hospital unavailable'), findsOneWidget);

      expect(find.text('PetCare Animal Hospital'), findsNothing);
    });

    testWidgets('shows an error when hospital loading fails', (tester) async {
      final hospitalRepository = _FakeHospitalRepository((hospitalId, _) async {
        throw StateError('Simulated Firestore failure');
      });

      await _pumpOverview(
        tester,
        hospitalRepository: hospitalRepository,
        appointmentRepository: _FakeAppointmentRepository(),
      );

      expect(find.text('Unable to load hospital'), findsOneWidget);

      expect(find.text('Retry'), findsOneWidget);
      expect(hospitalRepository.callCount, 1);
    });

    testWidgets('retries hospital loading after a failure', (tester) async {
      final hospitalRepository = _FakeHospitalRepository((
        hospitalId,
        callNumber,
      ) async {
        if (callNumber == 1) {
          throw StateError('Simulated network failure');
        }

        return _testHospital();
      });

      await _pumpOverview(
        tester,
        hospitalRepository: hospitalRepository,
        appointmentRepository: _FakeAppointmentRepository(),
      );

      expect(find.text('Unable to load hospital'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('PetCare Animal Hospital'), findsOneWidget);

      expect(hospitalRepository.callCount, 2);
    });

    testWidgets('calculates hospital appointment statistics correctly', (
      tester,
    ) async {
      final now = DateTime.now();

      final appointments = [
        _testAppointment(
          id: 'pending-001',
          status: 'pending',
          dateTime: now.add(const Duration(hours: 2)),
        ),
        _testAppointment(
          id: 'confirmed-001',
          status: 'confirmed',
          dateTime: now.add(const Duration(days: 2)),
        ),
        _testAppointment(
          id: 'rejected-001',
          status: 'rejected',
          dateTime: now.add(const Duration(days: 3)),
        ),
        _testAppointment(
          id: 'other-hospital-001',
          status: 'pending',
          dateTime: now.add(const Duration(days: 1)),
          hospitalId: 'hospital-002',
        ),
      ];

      final appointmentRepository = _FakeAppointmentRepository(
        onLoad: (_, _) async => appointments,
      );

      await _pumpOverview(
        tester,
        hospitalRepository: _FakeHospitalRepository(
          (_, _) async => _testHospital(),
        ),
        appointmentRepository: appointmentRepository,
      );

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Total Appointments'), findsOneWidget);

      // The repository must be queried only for the assigned hospital.
      expect(appointmentRepository.requestedHospitalIds, ['hospital-001']);

      // Another hospital's appointment must not affect the dashboard,
      // even if the repository accidentally returns extra records.
      expect(
        find.descendant(
          of: find
              .ancestor(of: find.text('Pending'), matching: find.byType(Column))
              .first,
          matching: find.text('1'),
        ),
        findsWidgets,
      );

      await tester.scrollUntilVisible(find.text('Upcoming Appointments'), 150);

      expect(find.text('Appointment #pending-'), findsOneWidget);

      expect(find.text('Appointment #confirme'), findsOneWidget);

      // Rejected appointments do not appear in upcoming appointments.
      expect(find.text('Appointment #rejected'), findsNothing);
    });

    testWidgets('shows an empty upcoming schedule', (tester) async {
      final appointmentRepository = _FakeAppointmentRepository();

      await _pumpOverview(
        tester,
        hospitalRepository: _FakeHospitalRepository(
          (_, _) async => _testHospital(),
        ),
        appointmentRepository: appointmentRepository,
      );

      expect(
        find.descendant(
          of: find
              .ancestor(of: find.text('Pending'), matching: find.byType(Column))
              .first,
          matching: find.text('0'),
        ),
        findsWidgets,
      );

      await tester.scrollUntilVisible(
        find.text('No upcoming appointments scheduled.'),
        150,
      );

      expect(find.text('No upcoming appointments scheduled.'), findsOneWidget);
    });

    testWidgets(
      'shows owner cancellation activity only for assigned hospital',
      (tester) async {
        final changedAt = DateTime(2026, 11, 7, 10, 30);
        final appointments = [
          _testAppointment(
            id: 'cancel-1',
            status: 'cancelled',
            dateTime: DateTime(2026, 11, 10, 9),
            updatedAt: changedAt,
          ),
          _testAppointment(
            id: 'other-cancel',
            status: 'cancelled',
            dateTime: DateTime(2026, 11, 10, 9),
            hospitalId: 'hospital-002',
            updatedAt: changedAt,
          ),
        ];
        await _pumpOverview(
          tester,
          hospitalRepository: _FakeHospitalRepository(
            (_, _) async => _testHospital(),
          ),
          appointmentRepository: _FakeAppointmentRepository(
            onLoad: (_, _) async => appointments,
          ),
        );
        await tester.scrollUntilVisible(find.text('Recent cancellations'), 150);
        expect(find.text('Appointment #cancel-1 cancelled'), findsOneWidget);
        expect(find.text('Appointment #other-ca cancelled'), findsNothing);
        expect(
          find.textContaining('Cancelled 7/11/2026 10:30'),
          findsOneWidget,
        );
      },
    );

    testWidgets('retries after appointment loading failure', (tester) async {
      final appointmentRepository = _FakeAppointmentRepository(
        onLoad: (_, callNumber) async {
          if (callNumber == 1) {
            // Allow the hospital FutureBuilder to finish mounting
            // before emitting the simulated appointment error.
            await Future<void>.delayed(const Duration(milliseconds: 10));

            throw StateError('Simulated appointment loading failure');
          }

          return <Appointment>[];
        },
      );

      await _pumpOverview(
        tester,
        hospitalRepository: _FakeHospitalRepository(
          (_, _) async => _testHospital(),
        ),
        appointmentRepository: appointmentRepository,
      );

      await tester.scrollUntilVisible(
        find.text('Unable to load appointment statistics.'),
        150,
      );

      expect(
        find.text('Unable to load appointment statistics.'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Retry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(appointmentRepository.callCount, 2);

      expect(find.text('Unable to load appointment statistics.'), findsNothing);
    });

    testWidgets('View All opens the appointments destination', (tester) async {
      var navigationCount = 0;

      await _pumpOverview(
        tester,
        hospitalRepository: _FakeHospitalRepository(
          (_, _) async => _testHospital(),
        ),
        appointmentRepository: _FakeAppointmentRepository(),
        onOpenAppointments: () {
          navigationCount++;
        },
      );

      await tester.scrollUntilVisible(find.text('View All'), 150);

      // scrollUntilVisible can locate a widget before its center
      // is within the test viewport. Ensure it is tappable.
      await tester.ensureVisible(find.text('View All'));

      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pump();

      expect(navigationCount, 1);
    });
  });
}
