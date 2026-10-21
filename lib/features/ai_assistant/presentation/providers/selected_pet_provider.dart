import 'package:flutter/material.dart';

import '../../../pets/domain/entities/pet.dart';
import '../../domain/entities/ai_pet_context.dart';

class SelectedPetProvider extends ChangeNotifier {
  Pet? _selectedPet;

  AIPetContext? _context;

  Pet? get selectedPet => _selectedPet;

  AIPetContext? get context => _context;

  void selectPet(Pet pet) {
    _selectedPet = pet;

    notifyListeners();
  }

  void updateContext(AIPetContext context) {
    _context = context;

    notifyListeners();
  }

  void clearContext() {
    _context = null;

    notifyListeners();
  }
}
