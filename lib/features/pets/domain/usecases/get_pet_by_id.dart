import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

class GetPetById {
  const GetPetById(this._repository);

  final PetRepository _repository;

  Future<Pet?> call(String petId) {
    return _repository.getPetById(petId);
  }
}
