import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

class GetPets {
  const GetPets(this._repository);

  final PetRepository _repository;

  Future<List<Pet>> call() {
    return _repository.getPets();
  }
}
