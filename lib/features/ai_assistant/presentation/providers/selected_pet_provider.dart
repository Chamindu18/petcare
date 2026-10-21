import 'package:flutter/material.dart';

import '../../../pets/domain/entities/pet.dart';
import '../../domain/entities/ai_pet_context.dart';
import '../../domain/usecases/create_pet_context.dart';
import '../../../health/domain/entities/medical_condition.dart';
import '../../../health/domain/entities/vaccination.dart';
import '../../../health/domain/entities/treatment.dart';
import '../../../health/domain/entities/health_measurement.dart';

class SelectedPetProvider extends ChangeNotifier {
  Pet? _selectedPet;
  final CreatePetContext _createPetContext = const CreatePetContext();

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

  void buildContext({
    required Pet pet,
    required List<MedicalCondition> conditions,
    required List<Vaccination> vaccinations,
    required List<Treatment> treatments,
    required List<HealthMeasurement> measurements,
  }) {
    _context = _createPetContext(
      pet: pet,
      conditions: conditions,
      vaccinations: vaccinations,
      treatments: treatments,
      measurements: measurements,
    );

    notifyListeners();
  }
}
