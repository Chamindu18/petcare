import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/appointments/domain/usecases/appointment_usecases.dart';
import 'package:petcare/features/appointments/presentation/pages/my_appointments_page.dart';
import 'package:petcare/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';
import 'package:petcare/features/pets/domain/entities/pet.dart';
import 'package:petcare/features/pets/domain/repositories/pet_repository.dart';
import 'package:petcare/features/queue/domain/entities/queue.dart';
import 'package:petcare/features/queue/domain/repositories/queue_repository.dart';
import 'package:petcare/features/queue/presentation/pages/owner_queue_details_page.dart';
import 'package:petcare/features/services/domain/entities/service.dart';
import 'package:petcare/features/services/domain/repositories/service_repository.dart';
import 'package:petcare/features/veterinary/domain/entities/veterinarian.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_repository.dart';

class _FakeAppointmentRepository implements AppointmentRepository {
  _FakeAppointmentRepository(this.appointments);

  final List<Appointment> appointments;

  @override
  Future<List<Appointment>> getAppointments() async => appointments;

  @override
  Future<Appointment> createAppointment(Appointment appointment) async =>
      appointment;

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

  @override
  Future<List<Appointment>> getAppointmentsByHospital(
    String hospitalId,
  ) async => [];

  @override
  Future<List<Appointment>> getAppointmentsByVeterinarian({
    required String vetId,
    required String hospitalId,
  }) async => [];
}

class _FakePetRepository implements PetRepository {
  @override
  Future<Pet> createPet(Pet pet) async => pet;

  @override
  Future<List<Pet>> getPets() async => [];

  @override
  Future<Pet?> getPetById(String petId) async => null;

  @override
  Future<void> updatePet(Pet pet) async {}

  @override
  Future<void> deletePet(String petId) async {}
}

class _FakeHospitalRepository implements HospitalRepository {
  @override
  Future<List<Hospital>> getHospitals() async => [];

  @override
  Future<Hospital?> getHospitalById(String hospitalId) async => null;
}

class _FakeServiceRepository implements ServiceRepository {
  @override
  Future<List<Service>> getServicesByHospital(String hospitalId) async => [];

  @override
  Future<Service?> getServiceById(String serviceId) async => null;
}

class _FakeVeterinarianRepository implements VeterinarianRepository {
  @override
  Future<List<Veterinarian>> getVeterinarians() async => [];

  @override
  Future<List<Veterinarian>> getVeterinariansByHospital(
    String hospitalId,
  ) async => [];

  @override
  Future<Veterinarian?> getVeterinarianById(String vetId) async => null;

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
}

class _FakeQueueRepository implements QueueRepository, OwnerQueueRepository {
  _FakeQueueRepository(this.queue, {this.position});

  final Queue? queue;
  final int? position;

  @override
  Future<Queue?> getQueueByAppointment(String appointmentId) async => queue;

  @override
  Future<Queue?> getQueueById(String queueId) async => queue;

  @override
  Future<int?> getOwnerQueuePosition({required String queueId}) async =>
      position;
}

Appointment appointment({String? queueId}) => Appointment(
  appointmentId: 'appointment-1',
  ownerId: 'owner-1',
  petId: 'pet-1',
  hospitalId: 'hospital-1',
  serviceId: 'service-1',
  vetId: 'vet-1',
  dateTime: DateTime(2026, 11, 7, 10, 30),
  reason: 'Checkup',
  status: 'confirmed',
  queueId: queueId,
  createdAt: DateTime(2026, 11, 1),
);

Queue queue() => Queue(
  queueId: 'queue-1',
  appointmentId: 'appointment-1',
  queueNumber: 7,
  currentServing: 0,
  position: 7,
  status: 'waiting',
  updatedAt: DateTime.utc(2026, 11, 7, 10),
  hospitalId: 'hospital-1',
  ownerId: 'owner-1',
  petId: 'pet-1',
);

Widget _pageFor({
  required List<Appointment> appointments,
  required _FakeQueueRepository queues,
}) {
  final provider = AppointmentProvider(
    getAppointments: GetAppointments(_FakeAppointmentRepository(appointments)),
    petRepository: _FakePetRepository(),
    hospitalRepository: _FakeHospitalRepository(),
    serviceRepository: _FakeServiceRepository(),
    veterinarianRepository: _FakeVeterinarianRepository(),
    queueRepository: queues,
  );
  return MaterialApp(
    home: MyAppointmentsPage(
      provider: provider,
      queueRepository: queues,
      ownerQueueRepository: queues,
    ),
  );
}

void main() {
  testWidgets('shows the linked queue and opens live details', (tester) async {
    final queues = _FakeQueueRepository(queue(), position: 2);
    await tester.pumpWidget(
      _pageFor(
        appointments: [appointment(queueId: 'queue-1')],
        queues: queues,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live queue'), findsOneWidget);
    expect(find.text('Queue number: 7'), findsOneWidget);
    expect(find.text('Waiting for your turn'), findsOneWidget);

    await tester.tap(find.text('View queue'));
    await tester.pumpAndSettle();

    expect(find.byType(OwnerQueueDetailsPage), findsOneWidget);
    expect(find.text('You are number 2'), findsOneWidget);
  });

  testWidgets('does not invent queue information before check-in', (
    tester,
  ) async {
    final queues = _FakeQueueRepository(queue(), position: 2);
    await tester.pumpWidget(
      _pageFor(appointments: [appointment()], queues: queues),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Queue details will appear after hospital staff checks in.'),
      findsOneWidget,
    );
    expect(find.textContaining('Queue number:'), findsNothing);
    expect(find.text('View queue'), findsNothing);
  });
}
