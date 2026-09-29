import 'dart:typed_data';

abstract class PetImageRepository {
  Future<String> uploadPetImage({
    required String petId,
    required Uint8List bytes,
  });

  Future<void> deletePetImage({required String imageUrl});
}
