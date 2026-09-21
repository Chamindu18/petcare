import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/pets/data/models/pet_model.dart';
import 'package:petcare/features/pets/domain/entities/pet.dart';

void main() {
  group('PetModel', () {
    final pet = PetModel(
      petId: 'pet-001',
      ownerId: 'owner-001',
      name: 'Milo',
      species: 'Dog',
      breed: 'Labrador',
      dob: DateTime(2023, 9, 20),
      gender: 'Male',
      weight: 12.5,
      imageUrl: 'https://example.com/milo.jpg',
      notes: 'Healthy',
      status: 'active',
    );

    test('creates a model from a map', () {
      final model = PetModel.fromMap({
        'petId': 'pet-001',
        'ownerId': 'owner-001',
        'name': 'Milo',
        'species': 'Dog',
        'breed': 'Labrador',
        'dob': '2023-09-20T00:00:00.000',
        'gender': 'Male',
        'weight': 12.5,
        'imageUrl': 'https://example.com/milo.jpg',
        'notes': 'Healthy',
        'status': 'active',
      });

      expect(model.petId, 'pet-001');
      expect(model.ownerId, 'owner-001');
      expect(model.name, 'Milo');
      expect(model.species, 'Dog');
      expect(model.breed, 'Labrador');
      expect(model.dob, DateTime(2023, 9, 20));
      expect(model.gender, 'Male');
      expect(model.weight, 12.5);
      expect(model.imageUrl, 'https://example.com/milo.jpg');
      expect(model.notes, 'Healthy');
      expect(model.status, 'active');
    });

    test('converts a model to a map', () {
      final map = pet.toMap();

      expect(map['petId'], 'pet-001');
      expect(map['ownerId'], 'owner-001');
      expect(map['name'], 'Milo');
      expect(map['species'], 'Dog');
      expect(map['breed'], 'Labrador');
      expect(map['dob'], '2023-09-20T00:00:00.000');
      expect(map['gender'], 'Male');
      expect(map['weight'], 12.5);
      expect(map['imageUrl'], 'https://example.com/milo.jpg');
      expect(map['notes'], 'Healthy');
      expect(map['status'], 'active');
    });

    test('creates a model from a domain entity', () {
      final entity = Pet(
        petId: 'pet-002',
        ownerId: 'owner-001',
        name: 'Luna',
        species: 'Cat',
        breed: 'Persian',
        dob: DateTime(2022, 5, 10),
        gender: 'Female',
        weight: 4.2,
        imageUrl: '',
        notes: '',
        status: 'active',
      );

      final model = PetModel.fromEntity(entity);

      expect(model.petId, entity.petId);
      expect(model.ownerId, entity.ownerId);
      expect(model.name, entity.name);
      expect(model.species, entity.species);
      expect(model.breed, entity.breed);
      expect(model.dob, entity.dob);
      expect(model.gender, entity.gender);
      expect(model.weight, entity.weight);
      expect(model.imageUrl, entity.imageUrl);
      expect(model.notes, entity.notes);
      expect(model.status, entity.status);
    });
  });
}
