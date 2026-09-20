import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

class UpdatePet {
  const UpdatePet(this._repository);

  final PetRepository _repository;

  Future<void> call(Pet pet) {
    return _repository.updatePet(pet);
  }
}
