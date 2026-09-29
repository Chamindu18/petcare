import '../repositories/pet_image_repository.dart';

class DeletePetImage {
  const DeletePetImage(this._repository);

  final PetImageRepository _repository;

  Future<void> call({required String imageUrl}) {
    return _repository.deletePetImage(imageUrl: imageUrl);
  }
}
