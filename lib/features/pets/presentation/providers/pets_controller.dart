import 'package:flutter/foundation.dart';

import '../../domain/entities/pet.dart';
import '../../domain/usecases/create_pet.dart';
import '../../domain/usecases/delete_pet.dart';
import '../../domain/usecases/get_pets.dart';
import '../../domain/usecases/update_pet.dart';

class PetsController extends ChangeNotifier {
  PetsController(
    this._createPet,
    this._getPets,
    this._updatePet,
    this._deletePet,
  );

  final CreatePet _createPet;
  final GetPets _getPets;
  final UpdatePet _updatePet;
  final DeletePet _deletePet;

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

  Future<void> create(Pet pet) async {
    await _run(() async {
      final createdPet = await _createPet(pet);

      _pets = [
        ..._pets,
        createdPet,
      ];
    });
  }

  Future<void> update(Pet pet) async {
    await _run(() async {
      await _updatePet(pet);

      final index = _pets.indexWhere(
        (existingPet) => existingPet.petId == pet.petId,
      );

      if (index != -1) {
        final updatedPets = List<Pet>.from(_pets);
        updatedPets[index] = pet;
        _pets = updatedPets;
      }
    });
  }

  Future<void> delete(String petId) async {
    await _run(() async {
      await _deletePet(petId);
      _pets = _pets.where((pet) => pet.petId != petId).toList();
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_isLoading) return;

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
    if (_errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}