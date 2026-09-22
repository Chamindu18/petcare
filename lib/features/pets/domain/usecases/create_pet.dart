import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

class CreatePet {
  const CreatePet(this._repository);

  final PetRepository _repository;

  Future<Pet> call(Pet pet) {
    return _repository.createPet(pet);
  }
}