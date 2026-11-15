import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/theme/app_theme.dart';
import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/appointments/domain/usecases/appointment_usecases.dart';
import 'package:petcare/features/appointments/presentation/pages/veterinarian_appointment_details_page.dart';
import 'package:petcare/features/appointments/presentation/widgets/veterinarian_appointment_card.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';
import 'package:petcare/features/hospitals/domain/usecases/hospital_usecases.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/services/domain/entities/service.dart';
import 'package:petcare/features/services/domain/repositories/service_repository.dart';
import 'package:petcare/features/services/domain/usecases/service_usecases.dart';
import 'package:petcare/features/veterinary/domain/entities/veterinarian.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_assignment_repository.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_image_repository.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_repository.dart';
import 'package:petcare/features/veterinary/domain/usecases/get_current_veterinarian_assignment.dart';
import 'package:petcare/features/veterinary/domain/usecases/veterinarian_usecases.dart';
import 'package:petcare/features/veterinary/presentation/pages/veterinarian_dashboard_page.dart';
import 'package:petcare/features/veterinary/presentation/providers/veterinarian_workspace_controller.dart';

const _vet = Veterinarian(
  vetId: 'vet-1',
  hospitalId: 'hospital-1',
  name: 'Dr. Adams',
  active: true,
);

const _profile = UserProfile(
  uid: 'uid-1',
  fullName: 'Alex Adams',
  displayName: 'Alex',
  email: 'alex@example.com',
  phone: '0771234567',
  role: 'veterinarian',
  notificationEnabled: true,
  vetId: 'vet-1',
  hospitalId: 'hospital-1',
);

class _AssignmentRepository implements VeterinarianAssignmentRepository {
  @override
  Future<Veterinarian?> getCurrentAssignment() async => _vet;
}

class _AppointmentRepository implements AppointmentRepository {
  _AppointmentRepository(this.appointments);

  final List<Appointment> appointments;

  @override
  Future<List<Appointment>> getAppointmentsByVeterinarian({
    required String vetId,
    required String hospitalId,
  }) async {
    return appointments;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HospitalRepository implements HospitalRepository {
  @override
  Future<Hospital?> getHospitalById(String hospitalId) async {
    return const Hospital(
      hospitalId: 'hospital-1',
      name: 'Central Vet',
      location: 'Colombo',
      contact: '0112345678',
      hours: '8 AM - 6 PM',
      active: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ServiceRepository implements ServiceRepository {
  @override
  Future<List<Service>> getServicesByHospital(String hospitalId) async {
    return const [
      Service(
        serviceId: 'service-1',
        hospitalId: 'hospital-1',
        name: 'General Consultation',
        description: 'Routine checkup',
        active: true,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VeterinarianRepository implements VeterinarianRepository {
  @override
  Future<void> updateVeterinarianProfile({
    required String vetId,
    required String name,
    String? profileImageUrl,
    String? specialty,
    String? qualifications,
    int? experienceYears,
    String? bio,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageRepository implements VeterinarianImageRepository {
  @override
  Future<String> uploadVeterinarianImage({
    required String vetId,
    required Uint8List bytes,
  }) async {
    return 'https://example.test/vet.jpg';
  }
}

class _AuthRepository implements AuthRepository {
  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

VeterinarianWorkspaceController _buildController({
  List<Appointment> appointments = const [],
}) {
  final appointmentRepository = _AppointmentRepository(appointments);

  return VeterinarianWorkspaceController(
    getAssignment: GetCurrentVeterinarianAssignment(_AssignmentRepository()),
    getAppointments: GetAppointmentsByVeterinarian(appointmentRepository),
    getHospital: GetHospitalById(_HospitalRepository()),
    getServices: GetServicesByHospital(_ServiceRepository()),
    confirmAppointment: ConfirmAppointment(appointmentRepository),
    rejectAppointment: RejectAppointment(appointmentRepository),
    updateVeterinarianProfile: UpdateVeterinarianProfile(
      _VeterinarianRepository(),
    ),
    imageRepository: _ImageRepository(),
  );
}

Appointment _appointment() {
  final now = DateTime.now();

  return Appointment(
    appointmentId: 'appointment-1',
    ownerId: 'owner-1',
    petId: 'pet-1',
    hospitalId: 'hospital-1',
    serviceId: 'service-1',
    vetId: 'vet-1',
    dateTime: DateTime(now.year, now.month, now.day, 9),
    reason: 'Annual checkup',
    status: 'pending',
    createdAt: now,
  );
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required Size size,
  List<Appointment> appointments = const [],
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final controller = _buildController(appointments: appointments);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: VeterinarianDashboardPage(
        profile: _profile,
        controller: controller,
        authRepository: _AuthRepository(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('open details reflect refreshed appointment status', (
    tester,
  ) async {
    final pending = _appointment();
    final confirmed = Appointment(
      appointmentId: pending.appointmentId,
      ownerId: pending.ownerId,
      petId: pending.petId,
      hospitalId: pending.hospitalId,
      serviceId: pending.serviceId,
      vetId: pending.vetId,
      dateTime: pending.dateTime,
      reason: pending.reason,
      status: 'confirmed',
      createdAt: pending.createdAt,
    );

    Widget details(Appointment appointment) => MaterialApp(
      home: VeterinarianAppointmentDetailsPage(
        appointment: appointment,
        serviceName: 'General Consultation',
        onConfirm: (_) async => true,
        onReject: (_) async => true,
      ),
    );

    await tester.pumpWidget(details(pending));
    await tester.scrollUntilVisible(find.text('Confirm appointment'), 200);
    expect(find.text('Confirm appointment'), findsOneWidget);

    await tester.pumpWidget(details(confirmed));
    await tester.scrollUntilVisible(find.text('Open pet health passport'), 200);
    expect(find.text('Confirm appointment'), findsNothing);
    expect(find.text('Open pet health passport'), findsOneWidget);
  });

  group('VeterinarianDashboardPage quick actions', () {
    for (final size in const [
      Size(320, 640),
      Size(360, 800),
      Size(480, 800),
      Size(600, 800),
    ]) {
      testWidgets('lays out all actions without overflow at ${size.width}', (
        tester,
      ) async {
        await _pumpDashboard(tester, size: size);

        await tester.scrollUntilVisible(
          find.text('Manage Queue'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Scan Pet QR'), findsNothing);
        expect(find.text('Appointments'), findsWidgets);
        expect(find.text('Manage Queue'), findsOneWidget);
        expect(find.text('My Profile'), findsWidgets);
        expect(tester.takeException(), isNull);

        final manageQueue = tester.renderObject<RenderParagraph>(
          find.text('Manage Queue'),
        );
        expect(manageQueue.didExceedMaxLines, isFalse);
      });
    }
  });

  group('VeterinarianDashboardPage back navigation', () {
    testWidgets('returns from appointment details to the appointments tab', (
      tester,
    ) async {
      await _pumpDashboard(
        tester,
        size: const Size(400, 800),
        appointments: [_appointment()],
      );

      await tester.tap(find.text('Appointments').last);
      await tester.pumpAndSettle();

      expect(find.byType(VeterinarianAppointmentCard), findsOneWidget);

      await tester.tap(find.byType(VeterinarianAppointmentCard));
      await tester.pumpAndSettle();

      expect(find.text('Appointment Details'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsNothing);
      expect(find.byType(VeterinarianAppointmentCard), findsOneWidget);
    });

    testWidgets('system back returns from a tab to the dashboard home', (
      tester,
    ) async {
      await _pumpDashboard(tester, size: const Size(400, 800));

      await tester.tap(find.text('Appointments').last);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets(
      'edit profile has a back button and returns to the profile tab',
      (tester) async {
        await _pumpDashboard(tester, size: const Size(400, 800));

        await tester.tap(find.text('Profile').last);
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Edit profile'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Edit profile'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('Edit Profile'), findsNothing);
        expect(find.text('Professional details'), findsOneWidget);
      },
    );
  });
}
