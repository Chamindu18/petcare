import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../models/treatment_model.dart';

class FirebaseTreatmentRepository implements TreatmentRepository {
  FirebaseTreatmentRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _treatmentsCollection =>
      _firestore.collection('treatments');

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const TreatmentRepositoryException(
        'You must be signed in to access treatments.',
      );
    }

    return user.uid;
  }

  @override
  Future<Treatment> createTreatment(Treatment treatment) async {
    _currentUserId;

    final document = _treatmentsCollection.doc();

    final persistedTreatment = Treatment(
      treatmentId: document.id,
      petId: treatment.petId,
      name: treatment.name,
      status: treatment.status,
      source: treatment.source,
      startDate: treatment.startDate,
      endDate: treatment.endDate,
      notes: treatment.notes,
      createdAt: treatment.createdAt,
      updatedAt: treatment.updatedAt,
    );

    final treatmentModel = TreatmentModel.fromEntity(persistedTreatment);

    await document.set(treatmentModel.toMap());

    return persistedTreatment;
  }

  @override
  Future<List<Treatment>> getTreatments(String petId) async {
    _currentUserId;

    final snapshot = await _treatmentsCollection
        .where('petId', isEqualTo: petId)
        .get();

    return snapshot.docs
        .map((document) => TreatmentModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<Treatment?> getTreatmentById(String petId, String treatmentId) async {
    _currentUserId;

    final document = await _treatmentsCollection.doc(treatmentId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['petId'] != petId) {
      return null;
    }

    return TreatmentModel.fromMap(data);
  }

  @override
  Future<void> updateTreatment(Treatment treatment) async {
    _currentUserId;

    final document = await _treatmentsCollection
        .doc(treatment.treatmentId)
        .get();

    if (!document.exists) {
      throw const TreatmentRepositoryException('Treatment was not found.');
    }

    final existingData = document.data();

    if (existingData == null || existingData['petId'] != treatment.petId) {
      throw const TreatmentRepositoryException(
        'You are not authorized to update this treatment.',
      );
    }

    final treatmentModel = TreatmentModel.fromEntity(treatment);

    await document.reference.update(treatmentModel.toMap());
  }

  @override
  Future<void> deleteTreatment(String petId, String treatmentId) async {
    _currentUserId;

    final document = await _treatmentsCollection.doc(treatmentId).get();

    if (!document.exists) {
      return;
    }

    final data = document.data();

    if (data == null || data['petId'] != petId) {
      throw const TreatmentRepositoryException(
        'You are not authorized to delete this treatment.',
      );
    }

    await document.reference.delete();
  }
}

class TreatmentRepositoryException implements Exception {
  const TreatmentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
