import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../models/appointment_model.dart';
import '../datasources/appointment_scheduling_datasource.dart';
import '../../../notifications/data/notification_event.dart';

class FirebaseAppointmentRepository
    implements AppointmentRepository, AppointmentAssignmentRepository {
  FirebaseAppointmentRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AppointmentSchedulingDataSource? schedulingDataSource,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _scheduling =
           schedulingDataSource ??
           FirebaseAppointmentSchedulingDataSource(auth: auth);

  final AppointmentSchedulingDataSource _scheduling;
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
    // Generate once before invoking the server, so transport retries can reuse
    // the same request ID and cannot create another appointment silently.
    _currentUserId;
    final data = await _scheduling.reserve({
      'action': 'create',
      'appointmentId': _appointmentsCollection.doc().id,
      'petId': appointment.petId,
      'hospitalId': appointment.hospitalId,
      'serviceId': appointment.serviceId,
      'vetId': appointment.vetId,
      'dateTime': appointment.dateTime.toUtc().toIso8601String(),
      'reason': appointment.reason,
    });
    return AppointmentModel.fromMap(data);
  }

  Map<String, dynamic> _schedule(Map<String, dynamic> data) => {
    'vetId': data['vetId'],
    'hospitalId': data['hospitalId'],
    'serviceId': data['serviceId'],
    'dateTime': data['dateTime'],
    'status': data['status'],
    if (data['durationMinutes'] != null)
      'durationMinutes': data['durationMinutes'],
  };

  @override
  Future<List<Appointment>> getAppointments() async {
    final ownerId = _currentUserId;

    final snapshot = await _appointmentsCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return snapshot.docs
        .map(
          (document) => AppointmentModel.fromMap({
            ...document.data(),
            'appointmentId': document.id,
          }),
        )
        .toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId) async {
    final snapshot = await _appointmentsCollection
        .where('hospitalId', isEqualTo: hospitalId)
        .get();

    return snapshot.docs
        .map(
          (document) => AppointmentModel.fromMap({
            ...document.data(),
            'appointmentId': document.id,
          }),
        )
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
        .map(
          (document) => AppointmentModel.fromMap({
            ...document.data(),
            'appointmentId': document.id,
          }),
        )
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

    return AppointmentModel.fromMap({...data, 'appointmentId': document.id});
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    _currentUserId;
    await _scheduling.reserve({
      'action': 'update',
      'appointmentId': appointment.appointmentId,
      'hospitalId': appointment.hospitalId,
      'serviceId': appointment.serviceId,
      'vetId': appointment.vetId,
      'dateTime': appointment.dateTime.toUtc().toIso8601String(),
      'reason': appointment.reason,
    });
  }

  @override
  Future<void> reassignVeterinarian({
    required String appointmentId,
    required String hospitalId,
    required String vetId,
  }) async {
    _currentUserId;
    await _scheduling.reserve({
      'action': 'reassign',
      'appointmentId': appointmentId,
      'hospitalId': hospitalId,
      'vetId': vetId,
    });
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

      transaction.set(
        _firestore.collection('appointment_schedule').doc(appointmentId),
        _schedule({...data, 'status': nextStatus}),
      );
      transaction.update(appointmentReference, {
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (nextStatus == 'confirmed' || nextStatus == 'rejected') {
        NotificationEvent.create(
          transaction,
          _firestore,
          recipientId: data['ownerId'] as String,
          type: 'appointment_$nextStatus',
          message: nextStatus == 'confirmed'
              ? 'Your appointment was confirmed.'
              : 'Your appointment was rejected.',
          targetType: 'appointment',
          targetId: appointmentId,
          details: {'appointmentTime': data['dateTime']},
        );
      }
    });
  }
}

class AppointmentRepositoryException implements Exception {
  const AppointmentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
