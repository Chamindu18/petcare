import 'dart:typed_data';

import '../repositories/adoption_image_repository.dart';

class UploadAdoptionImage {
  const UploadAdoptionImage(this._repository);

  final AdoptionImageRepository _repository;

  Future<String> call({
    required String listingId,
    required Uint8List bytes,
  }) {
    return _repository.uploadAdoptionImage(
      listingId: listingId,
      bytes: bytes,
    );
  }
}