import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../domain/repositories/pet_image_repository.dart';

class CloudinaryPetImageRepository implements PetImageRepository {
  CloudinaryPetImageRepository({
    required this._cloudName,
    required this._uploadPreset,
    http.Client? httpClient,
    FirebaseAuth? auth,
  }) : _client = httpClient ?? http.Client(),
       _auth = auth ?? FirebaseAuth.instance {
    if (_cloudName.isEmpty) {
      throw const PetImageRepositoryException(
        'Cloudinary cloud name is not configured. Set CLOUDINARY_CLOUD_NAME.',
      );
    }
    if (_uploadPreset.isEmpty) {
      throw const PetImageRepositoryException(
        'Cloudinary upload preset is not configured. Set CLOUDINARY_UPLOAD_PRESET.',
      );
    }
  }

  final String _cloudName;
  final String _uploadPreset;
  final http.Client _client;
  final FirebaseAuth _auth;

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const PetImageRepositoryException(
        'You must be signed in to manage pet images.',
      );
    }

    return user.uid;
  }

  @override
  Future<String> uploadPetImage({
    required String petId,
    required Uint8List bytes,
  }) async {
    final ownerId = _currentUserId;

    if (petId.trim().isEmpty) {
      throw const PetImageRepositoryException(
        'A valid pet ID is required for the image upload.',
      );
    }

    if (bytes.isEmpty) {
      throw const PetImageRepositoryException(
        'The selected pet image is empty.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'pet-images/$ownerId/$petId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${DateTime.now().microsecondsSinceEpoch}.jpg',
        ),
      );

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw const PetImageRepositoryException(
                'The pet image upload timed out. Please try again.',
              );
            },
          );

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        throw PetImageRepositoryException(_mapError(responseBody));
      }

      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final secureUrl = jsonResponse['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw const PetImageRepositoryException(
          'Upload succeeded but no secure URL was returned.',
        );
      }

      return secureUrl;
    } on PetImageRepositoryException {
      rethrow;
    } on FormatException {
      throw const PetImageRepositoryException(
        'Invalid response from image storage service.',
      );
    } catch (_) {
      throw const PetImageRepositoryException(
        'Unable to upload the pet image. Please try again.',
      );
    }
  }

  @override
  Future<void> deletePetImage({required String imageUrl}) async {
    if (imageUrl.trim().isEmpty) {
      return;
    }

    final isCloudinaryUrl = imageUrl.contains('cloudinary.com');

    if (!isCloudinaryUrl) {
      return;
    }

    return;
  }

  String _mapError(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;

      if (message != null && message.isNotEmpty) {
        return message;
      }
    } on FormatException {
      // Ignore parsing errors, fall through to default message.
    }

    return 'Unable to upload the pet image. Please try again.';
  }
}

class PetImageRepositoryException implements Exception {
  const PetImageRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
