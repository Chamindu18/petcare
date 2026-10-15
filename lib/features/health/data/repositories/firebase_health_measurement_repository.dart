import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/health_measurement.dart';
import '../../domain/repositories/health_measurement_repository.dart';
import '../models/health_measurement_model.dart';

class FirebaseHealthMeasurementRepository
    implements HealthMeasurementRepository {
  FirebaseHealthMeasurementRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _measurementsCollection =>
      _firestore.collection('health_measurements');

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const HealthMeasurementRepositoryException(
        'You must be signed in to access health measurements.',
      );
    }

    return user.uid;
  }

  @override
  Future<HealthMeasurement> createHealthMeasurement(
    HealthMeasurement measurement,
  ) async {
    _currentUserId;

    final document = _measurementsCollection.doc();

    final persistedMeasurement = HealthMeasurement(
      measurementId: document.id,
      petId: measurement.petId,
      type: measurement.type,
      value: measurement.value,
      unit: measurement.unit,
      recordedAt: measurement.recordedAt,
      createdAt: measurement.createdAt,
      updatedAt: measurement.updatedAt,
    );

    final measurementModel = HealthMeasurementModel.fromEntity(
      persistedMeasurement,
    );

    await document.set(measurementModel.toMap());

    return persistedMeasurement;
  }

  @override
  Future<List<HealthMeasurement>> getHealthMeasurements(String petId) async {
    _currentUserId;

    final snapshot = await _measurementsCollection
        .where('petId', isEqualTo: petId)
        .get();

    return snapshot.docs
        .map((document) => HealthMeasurementModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<HealthMeasurement?> getHealthMeasurementById(
    String petId,
    String measurementId,
  ) async {
    _currentUserId;

    final document = await _measurementsCollection.doc(measurementId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['petId'] != petId) {
      return null;
    }

    return HealthMeasurementModel.fromMap(data);
  }

  @override
  Future<void> updateHealthMeasurement(HealthMeasurement measurement) async {
    _currentUserId;

    final document = await _measurementsCollection
        .doc(measurement.measurementId)
        .get();

    if (!document.exists) {
      throw const HealthMeasurementRepositoryException(
        'Health measurement was not found.',
      );
    }

    final existingData = document.data();

    if (existingData == null || existingData['petId'] != measurement.petId) {
      throw const HealthMeasurementRepositoryException(
        'You are not authorized to update this health measurement.',
      );
    }

    final measurementModel = HealthMeasurementModel.fromEntity(measurement);

    await document.reference.update(measurementModel.toMap());
  }

  @override
  Future<void> deleteHealthMeasurement(
    String petId,
    String measurementId,
  ) async {
    _currentUserId;

    final document = await _measurementsCollection.doc(measurementId).get();

    if (!document.exists) {
      return;
    }

    final data = document.data();

    if (data == null || data['petId'] != petId) {
      throw const HealthMeasurementRepositoryException(
        'You are not authorized to delete this health measurement.',
      );
    }

    await document.reference.delete();
  }
}

class HealthMeasurementRepositoryException implements Exception {
  const HealthMeasurementRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
