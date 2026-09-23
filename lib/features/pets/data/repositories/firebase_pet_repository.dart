import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../models/pet_model.dart';

class FirebasePetRepository implements PetRepository {
  FirebasePetRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _petsCollection =>
      _firestore.collection('pets');

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const PetRepositoryException(
        'You must be signed in to access pets.',
      );
    }

    return user.uid;
  }

  @override
  Future<Pet> createPet(Pet pet) async {
    final ownerId = _currentUserId;

    // Firestore is the source of truth for the document ID.
    final document = _petsCollection.doc();

    final persistedPet = Pet(
      petId: document.id,
      ownerId: ownerId,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      dob: pet.dob,
      gender: pet.gender,
      weight: pet.weight,
      imageUrl: pet.imageUrl,
      notes: pet.notes,
      status: pet.status,
    );

    final petModel = PetModel.fromEntity(persistedPet);

    await document.set(petModel.toMap());

    return persistedPet;
  }

  @override
  Future<List<Pet>> getPets() async {
    final ownerId = _currentUserId;

    final snapshot = await _petsCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return snapshot.docs
        .map((document) => PetModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<Pet?> getPetById(String petId) async {
    final ownerId = _currentUserId;

    final document = await _petsCollection.doc(petId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['ownerId'] != ownerId) {
      return null;
    }

    return PetModel.fromMap(data);
  }

  @override
  Future<void> updatePet(Pet pet) async {
    final ownerId = _currentUserId;

    final document = await _petsCollection.doc(pet.petId).get();

    if (!document.exists) {
      throw const PetRepositoryException('Pet was not found.');
    }

    final existingData = document.data();

    if (existingData == null || existingData['ownerId'] != ownerId) {
      throw const PetRepositoryException(
        'You are not authorized to update this pet.',
      );
    }

    final petModel = PetModel.fromEntity(
      Pet(
        petId: pet.petId,
        ownerId: ownerId,
        name: pet.name,
        species: pet.species,
        breed: pet.breed,
        dob: pet.dob,
        gender: pet.gender,
        weight: pet.weight,
        imageUrl: pet.imageUrl,
        notes: pet.notes,
        status: pet.status,
      ),
    );

    await document.reference.update(petModel.toMap());
  }

  @override
  Future<void> deletePet(String petId) async {
    final ownerId = _currentUserId;

    final document = await _petsCollection.doc(petId).get();

    if (!document.exists) {
      return;
    }

    final data = document.data();

    if (data == null || data['ownerId'] != ownerId) {
      throw const PetRepositoryException(
        'You are not authorized to delete this pet.',
      );
    }

    await document.reference.delete();
  }
}

class PetRepositoryException implements Exception {
  const PetRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}