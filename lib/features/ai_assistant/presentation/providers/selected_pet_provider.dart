import 'package:flutter/material.dart';

import '../../../pets/domain/entities/pet.dart';

class SelectedPetProvider extends ChangeNotifier {
  Pet? _selectedPet;

  Pet? get selectedPet => _selectedPet;

  void selectPet(Pet pet) {
    _selectedPet = pet;
    notifyListeners();
  }
}
