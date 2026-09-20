import '../repositories/pet_repository.dart';

class DeletePet {
  const DeletePet(this._repository);

  final PetRepository _repository;

  Future<void> call(String petId) {
    return _repository.deletePet(petId);
  }
}
