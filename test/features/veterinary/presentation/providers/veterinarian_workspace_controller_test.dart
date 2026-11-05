import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/appointments/domain/usecases/appointment_usecases.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';
import 'package:petcare/features/hospitals/domain/usecases/hospital_usecases.dart';
import 'package:petcare/features/services/domain/entities/service.dart';
import 'package:petcare/features/services/domain/repositories/service_repository.dart';
import 'package:petcare/features/services/domain/usecases/service_usecases.dart';
import 'package:petcare/features/veterinary/domain/entities/veterinarian.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_assignment_repository.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_image_repository.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_repository.dart';
import 'package:petcare/features/veterinary/domain/usecases/get_current_veterinarian_assignment.dart';
import 'package:petcare/features/veterinary/domain/usecases/veterinarian_usecases.dart';
import 'package:petcare/features/veterinary/presentation/providers/veterinarian_workspace_controller.dart';

final _now = DateTime.now();

Veterinarian _vet() => const Veterinarian(
  vetId: 'vet-1',
  hospitalId: 'hospital-1',
  name: 'Dr. Adams',
  active: true,
);

Appointment _appointment({
  required String id,
  String status = 'pending',
  DateTime? dateTime,
}) {
  return Appointment(
    appointmentId: id,
    ownerId: 'owner-1',
    petId: 'pet-1',
    hospitalId: 'hospital-1',
    serviceId: 'service-1',
    vetId: 'vet-1',
    dateTime: dateTime ?? _now,
    reason: 'Checkup',
    status: status,
    createdAt: _now,
  );
}

class _AssignmentRepository implements VeterinarianAssignmentRepository {
  _AssignmentRepository(this.value);

  Veterinarian? value;
  Object? error;

  @override
  Future<Veterinarian?> getCurrentAssignment() async {
    if (error != null) throw error!;
    return value;
  }
}

class _AppointmentRepository implements AppointmentRepository {
  List<Appointment> values = [];
  Completer<List<Appointment>>? pending;
  Object? error;
  Object? confirmError;
  Object? rejectError;
  int confirmCalls = 0;
  int rejectCalls = 0;

  @override
  Future<List<Appointment>> getAppointmentsByVeterinarian({
    required String vetId,
    required String hospitalId,
  }) async {
    if (error != null) throw error!;
    return pending == null ? values : pending!.future;
  }

  @override
  Future<void> confirmAppointment(String appointmentId) async {
    confirmCalls++;
    if (confirmError != null) throw confirmError!;
  }

  @override
  Future<void> rejectAppointment(String appointmentId) async {
    rejectCalls++;
    if (rejectError != null) throw rejectError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HospitalRepository implements HospitalRepository {
  Hospital? value;
  Object? error;

  @override
  Future<Hospital?> getHospitalById(String hospitalId) async {
    if (error != null) throw error!;
    return value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ServiceRepository implements ServiceRepository {
  List<Service> values = [];
  Object? error;

  @override
  Future<List<Service>> getServicesByHospital(String hospitalId) async {
    if (error != null) throw error!;
    return values;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VeterinarianRepository implements VeterinarianRepository {
  Object? error;
  String? vetId;
  String? name;
  String? profileImageUrl;
  String? specialty;
  String? qualifications;
  int? experienceYears;
  String? bio;

  @override
  Future<void> updateVeterinarianProfile({
    required String vetId,
    required String name,
    String? profileImageUrl,
    String? specialty,
    String? qualifications,
    int? experienceYears,
    String? bio,
  }) async {
    this.vetId = vetId;
    this.name = name;
    this.profileImageUrl = profileImageUrl;
    this.specialty = specialty;
    this.qualifications = qualifications;
    this.experienceYears = experienceYears;
    this.bio = bio;
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageRepository implements VeterinarianImageRepository {
  String url = 'https://example.test/vet.jpg';
  Object? error;
  String? vetId;
  Uint8List? bytes;

  @override
  Future<String> uploadVeterinarianImage({
    required String vetId,
    required Uint8List bytes,
  }) async {
    this.vetId = vetId;
    this.bytes = bytes;
    if (error != null) throw error!;
    return url;
  }
}

({
  VeterinarianWorkspaceController controller,
  _AssignmentRepository assignment,
  _AppointmentRepository appointments,
  _HospitalRepository hospital,
  _ServiceRepository services,
  _VeterinarianRepository veterinarians,
  _ImageRepository images,
})
_buildController({Veterinarian? vet}) {
  final assignment = _AssignmentRepository(vet);
  final appointments = _AppointmentRepository();
  final hospital = _HospitalRepository();
  final services = _ServiceRepository();
  final veterinarians = _VeterinarianRepository();
  final images = _ImageRepository();

  final controller = VeterinarianWorkspaceController(
    getAssignment: GetCurrentVeterinarianAssignment(assignment),
    getAppointments: GetAppointmentsByVeterinarian(appointments),
    getHospital: GetHospitalById(hospital),
    getServices: GetServicesByHospital(services),
    confirmAppointment: ConfirmAppointment(appointments),
    rejectAppointment: RejectAppointment(appointments),
    updateVeterinarianProfile: UpdateVeterinarianProfile(veterinarians),
    imageRepository: images,
  );

  return (
    controller: controller,
    assignment: assignment,
    appointments: appointments,
    hospital: hospital,
    services: services,
    veterinarians: veterinarians,
    images: images,
  );
}

void main() {
  group('VeterinarianWorkspaceController', () {
    test('latest refresh wins when older appointments finish later', () async {
      final harness = _buildController(vet: _vet());
      final pending = Completer<List<Appointment>>();
      harness.appointments.pending = pending;
      final oldLoad = harness.controller.load();
      await Future<void>.delayed(Duration.zero);
      harness.appointments.pending = null;
      harness.appointments.values = [_appointment(id: 'new')];
      await harness.controller.refresh();
      pending.complete([_appointment(id: 'old')]);
      await oldLoad;
      expect(harness.controller.appointments.single.appointmentId, 'new');
      harness.controller.dispose();
    });

    test('foreign doctor result blocks all workspace data', () async {
      final harness = _buildController(vet: _vet());
      harness.assignment.value = const Veterinarian(
        vetId: 'other',
        hospitalId: 'hospital-1',
        name: 'Other',
        active: true,
      );
      harness.appointments.values = [_appointment(id: 'foreign')];
      await harness.controller.load();
      expect(harness.controller.appointments, isEmpty);
      expect(harness.controller.veterinarian, isNull);
      expect(harness.controller.loadErrorMessage, contains('assignment'));
      harness.controller.dispose();
    });

    test('foreign hospital result blocks all workspace data', () async {
      final harness = _buildController(vet: _vet());
      harness.appointments.values = [
        Appointment(
          appointmentId: 'foreign-hospital',
          ownerId: 'owner-1',
          petId: 'pet-1',
          hospitalId: 'hospital-2',
          serviceId: 'service-1',
          vetId: 'vet-1',
          dateTime: _now,
          reason: 'Checkup',
          status: 'pending',
          createdAt: _now,
        ),
      ];
      await harness.controller.load();
      expect(harness.controller.appointments, isEmpty);
      expect(harness.controller.veterinarian, isNull);
      expect(harness.controller.loadErrorMessage, contains('assignment'));
      harness.controller.dispose();
    });

    test('failed refresh clears previously displayed sensitive data', () async {
      final harness = _buildController(vet: _vet());
      harness.appointments.values = [_appointment(id: 'cached')];
      await harness.controller.load();
      harness.assignment.value = null;
      await harness.controller.refresh();
      expect(harness.controller.appointments, isEmpty);
      expect(harness.controller.veterinarian, isNull);
      expect(harness.controller.loadErrorMessage, isNotNull);
      harness.controller.dispose();
    });

    test(
      'loads the assignment, hospital, services and sorted appointments',
      () async {
        final harness = _buildController(vet: _vet());
        harness.hospital.value = const Hospital(
          hospitalId: 'hospital-1',
          name: 'Central Vet',
          location: 'Colombo',
          contact: '0112345678',
          hours: '8 AM - 6 PM',
          active: true,
        );
        harness.services.values = const [
          Service(
            serviceId: 'service-1',
            hospitalId: 'hospital-1',
            name: 'General Consultation',
            description: 'Routine checkup',
            active: true,
          ),
        ];
        harness.appointments.values = [
          _appointment(
            id: 'later',
            status: 'pending',
            dateTime: DateTime(_now.year, _now.month, _now.day + 1, 9),
          ),
          _appointment(
            id: 'today',
            status: 'confirmed',
            dateTime: DateTime(_now.year, _now.month, _now.day, 8),
          ),
        ];

        await harness.controller.load();

        expect(harness.controller.veterinarian?.vetId, 'vet-1');
        expect(harness.controller.hospitalName, 'Central Vet');
        expect(
          harness.controller.serviceNameFor('service-1'),
          'General Consultation',
        );
        expect(harness.controller.appointments.map((a) => a.appointmentId), [
          'today',
          'later',
        ]);
        expect(harness.controller.pendingCount, 1);
        expect(harness.controller.todayCount, 1);
        expect(harness.controller.upcomingCount, 1);
        expect(harness.controller.isLoading, isFalse);
        expect(harness.controller.loadErrorMessage, isNull);
      },
    );

    test(
      'keeps appointments when hospital and services fail to load',
      () async {
        final harness = _buildController(vet: _vet());
        harness.hospital.error = StateError('hospital unavailable');
        harness.services.error = StateError('services unavailable');
        harness.appointments.values = [_appointment(id: 'a1')];

        await harness.controller.load();

        expect(harness.controller.hospitalName, 'Assigned hospital');
        expect(harness.controller.serviceNameFor('service-1'), isNull);
        expect(harness.controller.appointments, hasLength(1));
        expect(harness.controller.loadErrorMessage, isNull);
      },
    );

    test('reports an error when the assignment cannot be verified', () async {
      final harness = _buildController();

      await harness.controller.load();

      expect(harness.controller.veterinarian, isNull);
      expect(harness.controller.loadErrorMessage, isNotNull);
      expect(harness.controller.isLoading, isFalse);
    });

    test(
      'confirms a pending appointment and updates the local status',
      () async {
        final harness = _buildController(vet: _vet());
        harness.appointments.values = [_appointment(id: 'a1')];
        await harness.controller.load();

        final result = await harness.controller.confirmAppointment('a1');

        expect(result, isTrue);
        expect(harness.appointments.confirmCalls, 1);
        expect(harness.controller.appointmentById('a1')?.status, 'confirmed');
        expect(harness.controller.actionErrorMessage, isNull);
        expect(harness.controller.isProcessingAppointment('a1'), isFalse);
      },
    );

    test(
      'rejects a pending appointment and updates the local status',
      () async {
        final harness = _buildController(vet: _vet());
        harness.appointments.values = [_appointment(id: 'a1')];
        await harness.controller.load();

        final result = await harness.controller.rejectAppointment('a1');

        expect(result, isTrue);
        expect(harness.appointments.rejectCalls, 1);
        expect(harness.controller.appointmentById('a1')?.status, 'rejected');
      },
    );

    test('does not update appointments that are not pending', () async {
      final harness = _buildController(vet: _vet());
      harness.appointments.values = [
        _appointment(id: 'a1', status: 'confirmed'),
      ];
      await harness.controller.load();

      final result = await harness.controller.confirmAppointment('a1');

      expect(result, isFalse);
      expect(harness.appointments.confirmCalls, 0);
      expect(harness.controller.actionErrorMessage, isNotNull);
      expect(harness.controller.appointmentById('a1')?.status, 'confirmed');
    });

    test('keeps the previous status when the command fails', () async {
      final harness = _buildController(vet: _vet());
      harness.appointments.values = [_appointment(id: 'a1')];
      harness.appointments.confirmError = StateError('permission denied');
      await harness.controller.load();

      final result = await harness.controller.confirmAppointment('a1');

      expect(result, isFalse);
      expect(harness.controller.appointmentById('a1')?.status, 'pending');
      expect(harness.controller.actionErrorMessage, isNotNull);
    });

    test('updates the professional profile and trims empty values', () async {
      final harness = _buildController(vet: _vet());
      await harness.controller.load();

      final result = await harness.controller.updateProfessionalProfile(
        name: '  Dr. Baker  ',
        profileImageUrl: ' https://example.test/vet.jpg ',
        specialty: '   ',
        qualifications: ' BVSc ',
        experienceYears: 7,
        bio: '',
      );

      expect(result, isTrue);
      expect(harness.veterinarians.vetId, 'vet-1');
      expect(harness.veterinarians.name, 'Dr. Baker');
      expect(
        harness.veterinarians.profileImageUrl,
        'https://example.test/vet.jpg',
      );
      expect(harness.veterinarians.specialty, isNull);
      expect(harness.veterinarians.qualifications, 'BVSc');
      expect(harness.veterinarians.experienceYears, 7);
      expect(harness.veterinarians.bio, isNull);
      expect(harness.controller.veterinarian?.name, 'Dr. Baker');
      expect(harness.controller.veterinarian?.specialty, isNull);
      expect(harness.controller.isSavingProfile, isFalse);
    });

    test('surfaces validation errors from the profile use case', () async {
      final harness = _buildController(vet: _vet());
      await harness.controller.load();

      final result = await harness.controller.updateProfessionalProfile(
        name: '   ',
        profileImageUrl: null,
        experienceYears: 81,
      );

      expect(result, isFalse);
      expect(harness.controller.profileErrorMessage, 'Name cannot be empty.');
      expect(harness.controller.veterinarian?.name, 'Dr. Adams');
      expect(harness.veterinarians.name, isNull);
    });

    test('uploads a profile image through the repository', () async {
      final harness = _buildController(vet: _vet());
      await harness.controller.load();
      final bytes = Uint8List.fromList([1, 2, 3]);

      final url = await harness.controller.uploadProfileImage(bytes);

      expect(url, 'https://example.test/vet.jpg');
      expect(harness.images.vetId, 'vet-1');
      expect(harness.images.bytes, bytes);
      expect(harness.controller.isUploadingImage, isFalse);
      expect(harness.controller.profileErrorMessage, isNull);
    });

    test('reports image upload errors', () async {
      final harness = _buildController(vet: _vet());
      await harness.controller.load();
      harness.images.error = const VeterinarianImageRepositoryException(
        'Upload failed.',
      );

      final url = await harness.controller.uploadProfileImage(
        Uint8List.fromList([1]),
      );

      expect(url, isNull);
      expect(harness.controller.profileErrorMessage, 'Upload failed.');
      expect(harness.controller.isUploadingImage, isFalse);
    });
  });
}
