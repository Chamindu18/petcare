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
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId) async {
    final snapshot = await _appointmentsCollection
        .where('hospitalId', isEqualTo: hospitalId)
        .get();

    return snapshot.docs
        .map((document) => AppointmentModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsByVeterinarian({
    required String vetId,
    required String hospitalId,
  }) async {
    final snapshot = await _appointmentsCollection
        .where('vetId', isEqualTo: vetId)
        .where('hospitalId', isEqualTo: hospitalId)
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
  Future<void> cancelAppointment(String appointmentId) {
    return _transitionAppointmentStatus(
      appointmentId: appointmentId,
      allowedCurrentStatuses: const {'pending', 'confirmed'},
      nextStatus: 'cancelled',
      failureMessage:
          'Only pending or confirmed appointments can be cancelled.',
    );
  }

  @override
  Future<void> confirmAppointment(String appointmentId) {
    return _transitionAppointmentStatus(
      appointmentId: appointmentId,
      allowedCurrentStatuses: const {'pending'},
      nextStatus: 'confirmed',
      failureMessage: 'Only pending appointments can be confirmed.',
    );
  }

  @override
  Future<void> rejectAppointment(String appointmentId) {
    return _transitionAppointmentStatus(
      appointmentId: appointmentId,
      allowedCurrentStatuses: const {'pending'},
      nextStatus: 'rejected',
      failureMessage: 'Only pending appointments can be rejected.',
    );
  }

  /// Applies an appointment status transition atomically.
  ///
  /// Firestore retries transactions when the document changes concurrently.
  /// Authorization must still be enforced by Firestore security rules.
  Future<void> _transitionAppointmentStatus({
    required String appointmentId,
    required Set<String> allowedCurrentStatuses,
    required String nextStatus,
    required String failureMessage,
  }) async {
    final appointmentReference = _appointmentsCollection.doc(appointmentId);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(appointmentReference);

      if (!snapshot.exists) {
        throw const AppointmentRepositoryException(
          'Appointment was not found.',
        );
      }

      final data = snapshot.data();

      if (data == null) {
        throw const AppointmentRepositoryException(
          'Appointment data was not found.',
        );
      }

      final currentStatus = data['status'];

      if (currentStatus is! String ||
          !allowedCurrentStatuses.contains(currentStatus)) {
        throw AppointmentRepositoryException(failureMessage);
      }

      transaction.update(appointmentReference, {
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

class AppointmentRepositoryException implements Exception {
  const AppointmentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
