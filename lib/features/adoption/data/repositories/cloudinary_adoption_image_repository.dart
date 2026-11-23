import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../domain/repositories/adoption_image_repository.dart';

class CloudinaryAdoptionImageRepository implements AdoptionImageRepository {
  CloudinaryAdoptionImageRepository({
    required this.cloudName,
    required this.uploadPreset,
    http.Client? httpClient,
    this._auth,
  }) : _client = httpClient ?? http.Client();

  final String cloudName;
  final String uploadPreset;
  final http.Client _client;
  final FirebaseAuth? _auth;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;

  @override
  Future<String> uploadAdoptionImage({
    required String listingId,
    required Uint8List bytes,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AdoptionImageRepositoryException(
        'You must be signed in to upload an adoption image.',
      );
    }

    if (listingId.trim().isEmpty) {
      throw const AdoptionImageRepositoryException(
        'A valid listing ID is required for the image upload.',
      );
    }

    if (bytes.isEmpty) {
      throw const AdoptionImageRepositoryException(
        'The selected image is empty.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'adoption-listing-images/${user.uid}/$listingId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${DateTime.now().microsecondsSinceEpoch}.jpg',
        ),
      );

    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw AdoptionImageRepositoryException(_mapError(responseBody));
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw const AdoptionImageRepositoryException(
          'Upload succeeded but no secure URL was returned.',
        );
      }

      return secureUrl;
    } on AdoptionImageRepositoryException {
      rethrow;
    } on FormatException {
      throw const AdoptionImageRepositoryException(
        'Invalid response from image storage service.',
      );
    } catch (_) {
      throw const AdoptionImageRepositoryException(
        'Unable to upload the adoption image. Please try again.',
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
      // Fall through to generic error.
    }

    return 'Unable to upload the adoption image. Please try again.';
  }
}

class AdoptionImageRepositoryException implements Exception {
  const AdoptionImageRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
