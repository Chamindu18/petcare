import 'package:flutter/foundation.dart';

import '../../domain/entities/pet.dart';
import '../../domain/usecases/create_pet.dart';
import '../../domain/usecases/delete_pet.dart';
import '../../domain/usecases/delete_pet_image.dart';
import '../../domain/usecases/get_pets.dart';
import '../../domain/usecases/update_pet.dart';
import '../../domain/usecases/upload_pet_image.dart';

class PetsController extends ChangeNotifier {
  PetsController(
    this._createPet,
    this._getPets,
    this._updatePet,
    this._deletePet, [
    this._uploadPetImage,
    this._deletePetImage,
  ]);
  final CreatePet _createPet;
  final GetPets _getPets;
  final UpdatePet _updatePet;
  final DeletePet _deletePet;

  final UploadPetImage? _uploadPetImage;
  final DeletePetImage? _deletePetImage;

  List<Pet> _pets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Pet> get pets => List.unmodifiable(_pets);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPets() async {
    await _run(() async {
      _pets = await _getPets();
    });
  }

  Future<void> create(Pet pet, {Uint8List? imageBytes}) async {
    await _run(() async {
      final createdPet = await _createPet(pet);

      if (imageBytes == null) {
        _pets = [..._pets, createdPet];
        return;
      }

      final uploadPetImage = _uploadPetImage;
      final deletePetImage = _deletePetImage;

      if (uploadPetImage == null || deletePetImage == null) {
        await _deletePet(createdPet.petId);

        throw const PetOperationException(
          'Pet image storage is not configured.',
        );
      }

      String? uploadedImageUrl;

      try {
        uploadedImageUrl = await uploadPetImage(
          petId: createdPet.petId,
          bytes: imageBytes,
        );

        final savedPet = _withImageUrl(createdPet, uploadedImageUrl);

        await _updatePet(savedPet);

        _pets = [..._pets, savedPet];
      } catch (_) {
        if (uploadedImageUrl != null) {
          try {
            await deletePetImage(imageUrl: uploadedImageUrl);
          } catch (_) {
            // Best-effort cleanup.
          }
        }

        try {
          await _deletePet(createdPet.petId);
        } catch (_) {
          // Best-effort rollback.
        }

        rethrow;
      }
    });
  }

  Future<void> update(
    Pet pet, {
    Uint8List? imageBytes,
    bool removeImage = false,
  }) async {
    await _run(() async {
      final index = _pets.indexWhere(
        (existingPet) => existingPet.petId == pet.petId,
      );

      final existingPet = index == -1 ? null : _pets[index];

      final oldImageUrl = existingPet?.imageUrl.trim().isNotEmpty == true
          ? existingPet!.imageUrl
          : null;

      String? newImageUrl;

      if (imageBytes != null) {
        final uploadPetImage = _uploadPetImage;
        final deletePetImage = _deletePetImage;

        if (uploadPetImage == null || deletePetImage == null) {
          throw const PetOperationException(
            'Pet image storage is not configured.',
          );
        }

        newImageUrl = await uploadPetImage(petId: pet.petId, bytes: imageBytes);
      }

      final updatedPet = _withImageUrl(
        pet,
        removeImage ? '' : newImageUrl ?? pet.imageUrl,
      );

      try {
        await _updatePet(updatedPet);
      } catch (_) {
        if (newImageUrl != null) {
          final deletePetImage = _deletePetImage;

          if (deletePetImage != null) {
            try {
              await deletePetImage(imageUrl: newImageUrl);
            } catch (_) {
              // Best-effort cleanup.
            }
          }
        }

        rethrow;
      }

      final deletePetImage = _deletePetImage;

      if (oldImageUrl != null &&
          (removeImage || newImageUrl != null) &&
          deletePetImage != null) {
        try {
          await deletePetImage(imageUrl: oldImageUrl);
        } catch (_) {
          // Firestore already contains the new state.
          // Old image cleanup is best effort.
        }
      }

      if (index != -1) {
        final updatedPets = List<Pet>.from(_pets);
        updatedPets[index] = updatedPet;
        _pets = updatedPets;
      }
    });
  }

  Future<void> delete(String petId) async {
    await _run(() async {
      final index = _pets.indexWhere((pet) => pet.petId == petId);

      final existingPet = index == -1 ? null : _pets[index];

      await _deletePet(petId);

      final deletePetImage = _deletePetImage;

      if (existingPet?.imageUrl.trim().isNotEmpty == true &&
          deletePetImage != null) {
        try {
          await deletePetImage(imageUrl: existingPet!.imageUrl);
        } catch (_) {
          // Pet deletion already succeeded.
          // Storage cleanup is best effort.
        }
      }

      _pets = _pets.where((pet) => pet.petId != petId).toList();
    });
  }

  Pet _withImageUrl(Pet pet, String imageUrl) {
    return Pet(
      petId: pet.petId,
      ownerId: pet.ownerId,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      dob: pet.dob,
      gender: pet.gender,
      weight: pet.weight,
      imageUrl: imageUrl,
      notes: pet.notes,
      status: pet.status,
    );
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await operation();
    } catch (_) {
      _errorMessage = 'Unable to complete the pet operation.';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

class PetOperationException implements Exception {
  const PetOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
