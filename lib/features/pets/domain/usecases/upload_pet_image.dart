import 'dart:typed_data';

import '../repositories/pet_image_repository.dart';

class UploadPetImage {
  const UploadPetImage(this._repository);

  final PetImageRepository _repository;

  Future<String> call({required String petId, required Uint8List bytes}) {
    return _repository.uploadPetImage(petId: petId, bytes: bytes);
  }
}
