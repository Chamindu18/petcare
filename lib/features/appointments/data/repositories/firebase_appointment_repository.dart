import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../models/appointment_model.dart';

class FirebaseAppointmentRepository implements AppointmentRepository {
  FirebaseAppointmentRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _appointmentsCollection =>
      _firestore.collection('appointments');

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const AppointmentRepositoryException(
        'You must be signed in to access appointments.',
      );
    }

    return user.uid;
  }

  @override
  Future<Appointment> createAppointment(Appointment appointment) async {
    final ownerId = _currentUserId;

    // Let Firestore generate the appointment document ID.
    final document = _appointmentsCollection.doc();

    final persistedAppointment = Appointment(
      appointmentId: document.id,
      ownerId: ownerId,
      petId: appointment.petId,
      hospitalId: appointment.hospitalId,
      serviceId: appointment.serviceId,
      vetId: appointment.vetId,
      dateTime: appointment.dateTime,
      reason: appointment.reason,
      status: appointment.status,
      queueId: appointment.queueId,
      createdAt: appointment.createdAt,
    );

    final appointmentModel = AppointmentModel.fromEntity(persistedAppointment);

    await document.set(appointmentModel.toMap());

    return persistedAppointment;
  }

  @override
  Future<List<Appointment>> getAppointments() async {
    final ownerId = _currentUserId;

    final snapshot = await _appointmentsCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return snapshot.docs
        .map((document) => AppointmentModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<Appointment?> getAppointmentById(String appointmentId) async {
    final ownerId = _currentUserId;

    final document = await _appointmentsCollection.doc(appointmentId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['ownerId'] != ownerId) {
      return null;
    }

    return AppointmentModel.fromMap(data);
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    final ownerId = _currentUserId;

    final document = await _appointmentsCollection
        .doc(appointment.appointmentId)
        .get();

    if (!document.exists) {
      throw const AppointmentRepositoryException('Appointment was not found.');
    }

    final existingData = document.data();

    if (existingData == null || existingData['ownerId'] != ownerId) {
      throw const AppointmentRepositoryException(
        'You are not authorized to update this appointment.',
      );
    }

    final appointmentModel = AppointmentModel.fromEntity(
      Appointment(
        appointmentId: appointment.appointmentId,
        ownerId: ownerId,
        petId: appointment.petId,
        hospitalId: appointment.hospitalId,
        serviceId: appointment.serviceId,
        vetId: appointment.vetId,
        dateTime: appointment.dateTime,
        reason: appointment.reason,
        status: appointment.status,
        queueId: appointment.queueId,
        createdAt: appointment.createdAt,
      ),
    );

    await document.reference.update(appointmentModel.toMap());
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    throw UnimplementedError(
      'Appointment cancellation requires the agreed appointment status value.',
    );
  }
}

class AppointmentRepositoryException implements Exception {
  const AppointmentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
