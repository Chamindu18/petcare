import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/repositories/pet_image_repository.dart';

class FirebasePetImageRepository implements PetImageRepository {
  FirebasePetImageRepository({FirebaseAuth? auth, FirebaseStorage? storage})
    : _auth = auth ?? FirebaseAuth.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

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

    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';

    final reference = _storage
        .ref()
        .child('pet-images')
        .child(ownerId)
        .child(petId)
        .child(fileName);

    try {
      await reference.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'ownerId': ownerId, 'petId': petId},
        ),
      );

      return await reference.getDownloadURL();
    } on FirebaseException catch (error) {
      throw PetImageRepositoryException(_mapFirebaseError(error));
    }
  }

  @override
  Future<void> deletePetImage({required String imageUrl}) async {
    if (imageUrl.trim().isEmpty) {
      return;
    }

    try {
      final reference = _storage.refFromURL(imageUrl);

      await reference.delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') {
        return;
      }

      throw PetImageRepositoryException(_mapFirebaseError(error));
    } on ArgumentError {
      throw const PetImageRepositoryException(
        'The pet image reference is invalid.',
      );
    }
  }

  String _mapFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'You are not authorized to manage this pet image.';

      case 'canceled':
        return 'The pet image upload was canceled.';

      case 'quota-exceeded':
        return 'Pet image storage is currently unavailable.';

      case 'retry-limit-exceeded':
        return 'The pet image upload timed out. Please try again.';

      default:
        return 'Unable to upload the pet image. Please try again.';
    }
  }
}

class PetImageRepositoryException implements Exception {
  const PetImageRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
