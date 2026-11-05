import 'dart:typed_data';

abstract class VeterinarianImageRepository {
  Future<String> uploadVeterinarianImage({
    required String vetId,
    required Uint8List bytes,
  });
}

class VeterinarianImageRepositoryException implements Exception {
  const VeterinarianImageRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
