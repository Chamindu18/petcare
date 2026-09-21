import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/pets/domain/entities/pet.dart';

void main() {
  group('Pet', () {
    test('creates a pet with the provided values', () {
      final pet = Pet(
        petId: 'pet-001',
        ownerId: 'owner-001',
        name: 'Milo',
        species: 'Dog',
        breed: 'Labrador',
        dob: DateTime(2023, 9, 20),
        gender: 'Male',
        weight: 12.5,
        imageUrl: '',
        notes: 'Healthy',
        status: 'active',
      );

      expect(pet.petId, 'pet-001');
      expect(pet.ownerId, 'owner-001');
      expect(pet.name, 'Milo');
      expect(pet.species, 'Dog');
      expect(pet.breed, 'Labrador');
      expect(pet.dob, DateTime(2023, 9, 20));
      expect(pet.gender, 'Male');
      expect(pet.weight, 12.5);
      expect(pet.imageUrl, '');
      expect(pet.notes, 'Healthy');
      expect(pet.status, 'active');
    });

    test('calculates age in completed years from date of birth', () {
      final today = DateTime.now();

      final dob = DateTime(today.year - 3, today.month, today.day);

      final pet = Pet(
        petId: 'pet-002',
        ownerId: 'owner-001',
        name: 'Luna',
        species: 'Cat',
        breed: 'Persian',
        dob: dob,
        gender: 'Female',
        weight: 4.2,
        imageUrl: '',
        notes: '',
        status: 'active',
      );

      expect(pet.ageInYears, 3);
    });
  });
}
