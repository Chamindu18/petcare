import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/cloudinary_config.dart';
import '../../domain/repositories/veterinarian_image_repository.dart';

class CloudinaryVeterinarianImageRepository
    implements VeterinarianImageRepository {
  CloudinaryVeterinarianImageRepository({
    String? cloudName,
    String? uploadPreset,
    http.Client? httpClient,
  }) : _cloudName = cloudName ?? CloudinaryConfig.cloudName,
       _uploadPreset = uploadPreset ?? CloudinaryConfig.uploadPreset,
       _client = httpClient ?? http.Client() {
    if (_cloudName.isEmpty) {
      throw const VeterinarianImageRepositoryException(
        'Cloudinary cloud name is not configured.',
      );
    }

    if (_uploadPreset.isEmpty) {
      throw const VeterinarianImageRepositoryException(
        'Cloudinary upload preset is not configured.',
      );
    }
  }

  final String _cloudName;
  final String _uploadPreset;
  final http.Client _client;

  @override
  Future<String> uploadVeterinarianImage({
    required String vetId,
    required Uint8List bytes,
  }) async {
    if (vetId.trim().isEmpty) {
      throw const VeterinarianImageRepositoryException(
        'A valid veterinarian ID is required for the image upload.',
      );
    }

    if (bytes.isEmpty) {
      throw const VeterinarianImageRepositoryException(
        'The selected profile image is empty.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'veterinarian-images/${vetId.trim()}'
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
              throw const VeterinarianImageRepositoryException(
                'The profile image upload timed out. Please try again.',
              );
            },
          );

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        throw VeterinarianImageRepositoryException(_mapError(responseBody));
      }

      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final secureUrl = jsonResponse['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw const VeterinarianImageRepositoryException(
          'Upload succeeded but no secure URL was returned.',
        );
      }

      return secureUrl;
    } on VeterinarianImageRepositoryException {
      rethrow;
    } on FormatException {
      throw const VeterinarianImageRepositoryException(
        'Invalid response from image storage service.',
      );
    } catch (error) {
      debugPrint('Veterinarian image upload failed: ${error.runtimeType}');
      throw const VeterinarianImageRepositoryException(
        'Unable to upload the profile image. Please try again.',
      );
    }
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
      return 'Unable to upload the profile image. Please try again.';
    }

    return 'Unable to upload the profile image. Please try again.';
  }
}
