import '../entities/pet.dart';

abstract interface class PetRepository {
  Future<Pet> createPet(Pet pet);

  Future<List<Pet>> getPets();

  Future<Pet?> getPetById(String petId);

  Future<void> updatePet(Pet pet);

  Future<void> deletePet(String petId);
}