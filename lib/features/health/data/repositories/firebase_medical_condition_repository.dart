import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/medical_condition.dart';
import '../../domain/repositories/medical_condition_repository.dart';
import '../models/medical_condition_model.dart';

class FirebaseMedicalConditionRepository implements MedicalConditionRepository {
  FirebaseMedicalConditionRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conditionsCollection =>
      _firestore.collection('medical_conditions');

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const MedicalConditionRepositoryException(
        'You must be signed in to access medical conditions.',
      );
    }

    return user.uid;
  }

  @override
  Future<MedicalCondition> createMedicalCondition(
    MedicalCondition condition,
  ) async {
    _currentUserId;

    final document = _conditionsCollection.doc();

    final persistedCondition = MedicalCondition(
      conditionId: document.id,
      petId: condition.petId,
      name: condition.name,
      status: condition.status,
      source: condition.source,
      diagnosisDate: condition.diagnosisDate,
      vetId: condition.vetId,
      notes: condition.notes,
      createdAt: condition.createdAt,
      updatedAt: condition.updatedAt,
    );

    final conditionModel = MedicalConditionModel.fromEntity(persistedCondition);

    await document.set(conditionModel.toMap());

    return persistedCondition;
  }

  @override
  Future<List<MedicalCondition>> getMedicalConditions(String petId) async {
    _currentUserId;

    final snapshot = await _conditionsCollection
        .where('petId', isEqualTo: petId)
        .get();

    return snapshot.docs
        .map((document) => MedicalConditionModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<MedicalCondition?> getMedicalConditionById(
    String petId,
    String conditionId,
  ) async {
    _currentUserId;

    final document = await _conditionsCollection.doc(conditionId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['petId'] != petId) {
      return null;
    }

    return MedicalConditionModel.fromMap(data);
  }

  @override
  Future<void> updateMedicalCondition(MedicalCondition condition) async {
    _currentUserId;

    final document = await _conditionsCollection
        .doc(condition.conditionId)
        .get();

    if (!document.exists) {
      throw const MedicalConditionRepositoryException(
        'Medical condition was not found.',
      );
    }

    final existingData = document.data();

    if (existingData == null || existingData['petId'] != condition.petId) {
      throw const MedicalConditionRepositoryException(
        'You are not authorized to update this medical condition.',
      );
    }

    final conditionModel = MedicalConditionModel.fromEntity(condition);

    await document.reference.update(conditionModel.toMap());
  }

  @override
  Future<void> deleteMedicalCondition(String petId, String conditionId) async {
    _currentUserId;

    final document = await _conditionsCollection.doc(conditionId).get();

    if (!document.exists) {
      return;
    }

    final data = document.data();

    if (data == null || data['petId'] != petId) {
      throw const MedicalConditionRepositoryException(
        'You are not authorized to delete this medical condition.',
      );
    }

    await document.reference.delete();
  }
}

class MedicalConditionRepositoryException implements Exception {
  const MedicalConditionRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
