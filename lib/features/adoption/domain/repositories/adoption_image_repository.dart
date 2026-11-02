import 'dart:typed_data';

abstract class AdoptionImageRepository {
  Future<String> uploadAdoptionImage({
    required String listingId,
    required Uint8List bytes,
  });
}