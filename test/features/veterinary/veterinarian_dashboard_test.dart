import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/appointments/data/repositories/firebase_appointment_repository.dart';
import 'package:petcare/features/appointments/data/datasources/appointment_scheduling_datasource.dart';
import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/appointments/domain/usecases/appointment_usecases.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';
import 'package:petcare/features/hospitals/domain/usecases/hospital_usecases.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/veterinary/data/repositories/firebase_veterinarian_assignment_repository.dart';
import 'package:petcare/features/veterinary/domain/entities/veterinarian.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_assignment_repository.dart';
import 'package:petcare/features/veterinary/domain/usecases/get_current_veterinarian_assignment.dart';
import 'package:petcare/features/veterinary/presentation/pages/veterinarian_dashboard_page.dart';

const vet = Veterinarian(
  vetId: 'directory',
  hospitalId: 'hospital',
  name: 'Doctor',
  active: true,
);
UserProfile profile(String uid) => UserProfile(
  uid: uid,
  fullName: 'Doctor',
  displayName: 'Doctor',
  email: '',
  phone: '',
  role: 'veterinarian',
  notificationEnabled: true,
);

class Assignments implements VeterinarianAssignmentRepository {
  Veterinarian? value = vet;
  @override
  Future<Veterinarian?> getCurrentAssignment() async => value;
}

class Hospitals implements HospitalRepository {
  Object? error;
  @override
  Future<Hospital?> getHospitalById(String id) async {
    if (error != null) throw error!;
    return const Hospital(
      hospitalId: 'hospital',
      name: 'Hospital',
      location: '',
      contact: '',
      hours: '',
      active: true,
    );
  }

  @override
  Future<List<Hospital>> getHospitals() async => [];
}

class Appointments implements AppointmentRepository {
  Object? error;
  Completer<List<Appointment>>? pending;
  final calls = <String>[];
  List<Appointment> result = [];
  @override
  Future<List<Appointment>> getAppointmentsByVeterinarian({
    required String vetId,
    required String hospitalId,
  }) async {
    calls.add('$hospitalId/$vetId');
    if (error != null) throw error!;
    return pending == null ? result : pending!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Scheduler implements AppointmentSchedulingDataSource {
  @override
  Future<Map<String, dynamic>> reserve(Map<String, dynamic> request) =>
      throw UnimplementedError();
}

void main() {
  late MockFirebaseAuth auth;
  late Assignments assignments;
  late Hospitals hospitals;
  late Appointments appointments;
  setUp(() {
    auth = MockFirebaseAuth(mockUser: MockUser(uid: 'uid'), signedIn: true);
    assignments = Assignments();
    hospitals = Hospitals();
    appointments = Appointments();
  });
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VeterinarianDashboardPage(
          profile: profile('uid'),
          auth: auth,
          getAssignment: GetCurrentVeterinarianAssignment(assignments),
          getHospital: GetHospitalById(hospitals),
          getAppointments: GetAppointmentsByVeterinarian(appointments),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('verified directory ID different from UID loads empty schedule', (
    tester,
  ) async {
    await mount(tester);
    expect(appointments.calls, ['hospital/directory']);
    expect(find.text('Appointment overview'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No appointments scheduled for today.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No appointments scheduled for today.'), findsOneWidget);
  });
  testWidgets('missing assignment blocks appointment reads safely', (
    tester,
  ) async {
    assignments.value = null;
    await mount(tester);
    expect(appointments.calls, isEmpty);
    expect(
      find.textContaining('assignment could not be verified'),
      findsOneWidget,
    );
  });
  for (final code in [
    'permission-denied',
    'failed-precondition',
    'unavailable',
  ]) {
    testWidgets('$code is classified and Retry recovers', (tester) async {
      appointments.error = FirebaseException(
        plugin: 'cloud_firestore',
        code: code,
      );
      await mount(tester);
      expect(find.text('Try again'), findsOneWidget);
      final expected = code == 'permission-denied'
          ? 'authorized'
          : code == 'failed-precondition'
          ? 'configuration'
          : 'connect';
      expect(find.textContaining(expected), findsOneWidget);
      appointments.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Appointment overview'), findsOneWidget);
      expect(appointments.calls.length, 2);
    });
  }
  testWidgets(
    'hospital network failure preserves schedule and Refresh recovers',
    (tester) async {
      hospitals.error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      await mount(tester);
      expect(find.text('Appointment overview'), findsOneWidget);
      expect(find.textContaining('Hospital details could not'), findsOneWidget);
      hospitals.error = null;
      await tester.tap(find.byTooltip('Refresh dashboard'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hospital details could not'), findsNothing);
    },
  );
  testWidgets('hospital authorization failure is not hidden', (tester) async {
    hospitals.error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    await mount(tester);
    expect(find.textContaining('authorized'), findsOneWidget);
    expect(find.text('Appointment overview'), findsNothing);
  });
  testWidgets('logout discards a previous doctor pending response', (
    tester,
  ) async {
    appointments.pending = Completer<List<Appointment>>();
    await tester.pumpWidget(
      MaterialApp(
        home: VeterinarianDashboardPage(
          profile: profile('uid'),
          auth: auth,
          getAssignment: GetCurrentVeterinarianAssignment(assignments),
          getHospital: GetHospitalById(hospitals),
          getAppointments: GetAppointmentsByVeterinarian(appointments),
        ),
      ),
    );
    await tester.pump();
    await auth.signOut();
    await tester.pump();
    appointments.pending!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Appointment overview'), findsNothing);
    expect(find.textContaining('session changed'), findsOneWidget);
  });
  testWidgets('switching doctor profiles replaces cached appointment data', (
    tester,
  ) async {
    await mount(tester);
    await auth.signOut();
    await tester.pump();
    auth.mockUser = MockUser(uid: 'second-uid');
    await auth.signInWithCustomToken('test-token');
    final uid = auth.currentUser!.uid;
    assignments.value = const Veterinarian(
      vetId: 'second-directory',
      hospitalId: 'hospital',
      name: 'Second',
      active: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: VeterinarianDashboardPage(
          profile: profile(uid),
          auth: auth,
          getAssignment: GetCurrentVeterinarianAssignment(assignments),
          getHospital: GetHospitalById(hospitals),
          getAppointments: GetAppointmentsByVeterinarian(appointments),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(appointments.calls, [
      'hospital/directory',
      'hospital/second-directory',
    ]);
    expect(find.text('Appointment overview'), findsOneWidget);
  });
  testWidgets('appointment clock uses Sri Lanka time for UTC timestamps', (
    tester,
  ) async {
    final at = DateTime.now().toUtc().add(const Duration(days: 2));
    final instant = DateTime.utc(at.year, at.month, at.day, 4);
    appointments.result = [
      Appointment(
        appointmentId: 'clock',
        ownerId: 'owner',
        petId: 'pet',
        hospitalId: 'hospital',
        serviceId: 'service',
        vetId: 'directory',
        dateTime: instant.toLocal(),
        reason: '',
        status: 'pending',
        createdAt: instant,
      ),
    ];
    await mount(tester);
    await tester.scrollUntilVisible(
      find.textContaining('9:30 AM'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('9:30 AM'), findsOneWidget);
  });
  test(
    'doctor query scopes appointments to both hospital and directory ID',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseAppointmentRepository(
        auth: auth,
        firestore: db,
        schedulingDataSource: Scheduler(),
      );
      for (final entry in [
        ('own', 'directory', 'hospital'),
        ('other', 'another', 'hospital'),
        ('wrong', 'directory', 'elsewhere'),
      ]) {
        await db.doc('appointments/${entry.$1}').set({
          'ownerId': 'owner',
          'petId': 'pet',
          'serviceId': 'service',
          'vetId': entry.$2,
          'hospitalId': entry.$3,
          'dateTime': '2026-11-05T04:00:00Z',
          'createdAt': '2026-11-01T04:00:00Z',
          'reason': '',
          'status': 'pending',
        });
      }
      final result = await repo.getAppointmentsByVeterinarian(
        vetId: 'directory',
        hospitalId: 'hospital',
      );
      expect(result.map((a) => a.appointmentId), ['own']);
    },
  );
  test(
    'malformed optional directory fields do not crash verified assignment',
    () async {
      final db = FakeFirebaseFirestore();
      await db.doc('users/uid').set({
        'role': 'veterinarian',
        'vetId': 'directory',
        'hospitalId': 'hospital',
      });
      await db.doc('veterinarians/directory').set({
        'userId': 'uid',
        'active': true,
        'hospitalId': 'hospital',
        'name': 42,
        'qualifications': ['legacy'],
        'experienceYears': 'many',
        'profileImageUrl': 99,
      });
      final repo = FirebaseVeterinarianAssignmentRepository(
        auth: auth,
        firestore: db,
      );
      expect((await repo.getCurrentAssignment())?.name, 'Veterinarian');
      await db.doc('veterinarians/directory').update({'experienceYears': '12'});
      expect((await repo.getCurrentAssignment())?.experienceYears, 12);
      for (final patch in [
        {'active': false},
        {'active': true, 'hospitalId': 'wrong'},
        {'hospitalId': 'hospital', 'userId': null},
      ]) {
        await db.doc('veterinarians/directory').update(patch);
        expect(await repo.getCurrentAssignment(), isNull);
      }
    },
  );
}
