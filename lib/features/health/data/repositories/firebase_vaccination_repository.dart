import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/vaccination.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../models/vaccination_model.dart';

class FirebaseVaccinationRepository implements VaccinationRepository {
  FirebaseVaccinationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _vaccinationsCollection =>
      _firestore.collection('vaccinations');

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const VaccinationRepositoryException(
        'You must be signed in to access vaccinations.',
      );
    }

    return user.uid;
  }

  @override
  Future<Vaccination> createVaccination(Vaccination vaccination) async {
    _currentUserId;

    final document = _vaccinationsCollection.doc();

    final persistedVaccination = Vaccination(
      vaccinationId: document.id,
      petId: vaccination.petId,
      name: vaccination.name,
      dateGiven: vaccination.dateGiven,
      nextDueDate: vaccination.nextDueDate,
      providerId: vaccination.providerId,
      notes: vaccination.notes,
      createdAt: vaccination.createdAt,
      updatedAt: vaccination.updatedAt,
    );

    final vaccinationModel = VaccinationModel.fromEntity(persistedVaccination);

    await document.set(vaccinationModel.toMap());

    return persistedVaccination;
  }

  @override
  Future<List<Vaccination>> getVaccinations(String petId) async {
    _currentUserId;

    final snapshot = await _vaccinationsCollection
        .where('petId', isEqualTo: petId)
        .get();

    return snapshot.docs
        .map((document) => VaccinationModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<Vaccination?> getVaccinationById(
    String petId,
    String vaccinationId,
  ) async {
    _currentUserId;

    final document = await _vaccinationsCollection.doc(vaccinationId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['petId'] != petId) {
      return null;
    }

    return VaccinationModel.fromMap(data);
  }

  @override
  Future<void> updateVaccination(Vaccination vaccination) async {
    _currentUserId;

    final document = await _vaccinationsCollection
        .doc(vaccination.vaccinationId)
        .get();

    if (!document.exists) {
      throw const VaccinationRepositoryException('Vaccination was not found.');
    }

    final existingData = document.data();

    if (existingData == null || existingData['petId'] != vaccination.petId) {
      throw const VaccinationRepositoryException(
        'You are not authorized to update this vaccination.',
      );
    }

    final vaccinationModel = VaccinationModel.fromEntity(vaccination);

    await document.reference.update(vaccinationModel.toMap());
  }

  @override
  Future<void> deleteVaccination(String petId, String vaccinationId) async {
    _currentUserId;

    final document = await _vaccinationsCollection.doc(vaccinationId).get();

    if (!document.exists) {
      return;
    }

    final data = document.data();

    if (data == null || data['petId'] != petId) {
      throw const VaccinationRepositoryException(
        'You are not authorized to delete this vaccination.',
      );
    }

    await document.reference.delete();
  }
}

class VaccinationRepositoryException implements Exception {
  const VaccinationRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
