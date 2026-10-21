import 'package:flutter/material.dart';

import '../../domain/entities/ai_message.dart';
import '../../../pets/domain/entities/pet.dart';

import '../../domain/entities/ai_pet_context.dart';

import '../../domain/usecases/generate_local_health_summary.dart';
import '../../domain/usecases/generate_local_preventive_care.dart';
import '../../domain/usecases/generate_local_vet_prep.dart';

import '../../domain/usecases/generate_pet_overview.dart';
import '../providers/selected_pet_provider.dart';

class AIProvider extends ChangeNotifier {
  bool isLoading = false;
  final GenerateLocalHealthSummary _healthSummaryGenerator =
      const GenerateLocalHealthSummary();

  final GenerateLocalPreventiveCare _preventiveCareGenerator =
      const GenerateLocalPreventiveCare();

  final GenerateLocalVetPrep _vetPrepGenerator = const GenerateLocalVetPrep();
  final GeneratePetOverview _overviewGenerator = const GeneratePetOverview();

  Map<String, dynamic>? petOverview;

  final List<AIMessage> messages = [
    AIMessage(
      message: "Hello! I'm PetCare AI. How can I help you today?",
      isUser: false,
    ),
  ];

  String healthSummary = '';
  String preventiveCare = '';
  String vetVisitPrep = '';

  Pet? _selectedPet;

  Pet? get selectedPet => _selectedPet;

  void setSelectedPet(Pet pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(AIMessage(message: text, isUser: true));

    notifyListeners();

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    messages.add(
      AIMessage(
        message: "This is a sample AI response for '$text'",
        isUser: false,
      ),
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> generateHealthSummary() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    healthSummary = '''
  No pet health records connected yet.

  Health summaries will be generated
  from the selected pet records.
  ''';

    isLoading = false;
    notifyListeners();
  }

  Future<void> generatePreventiveCare() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    preventiveCare = '''
  No preventive recommendations available.

  Recommendations will be generated
  from the selected pet records.
  ''';

    isLoading = false;
    notifyListeners();
  }

  Future<void> generateVetVisitPrep() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    vetVisitPrep = '''
  No visit preparation data available.

  Preparation notes will be generated
  from the selected pet records.
  ''';

    isLoading = false;
    notifyListeners();
  }

  Future<void> buildHealthSummary(AIPetContext context) async {
    isLoading = true;

    notifyListeners();

    healthSummary = _healthSummaryGenerator(context);

    isLoading = false;

    notifyListeners();
  }

  Future<void> buildPreventiveCare(AIPetContext context) async {
    isLoading = true;

    notifyListeners();

    preventiveCare = _preventiveCareGenerator(context);

    isLoading = false;

    notifyListeners();
  }

  Future<void> buildVetVisitPrep(AIPetContext context) async {
    isLoading = true;

    notifyListeners();

    vetVisitPrep = _vetPrepGenerator(context);

    isLoading = false;

    notifyListeners();
  }

  Future<void> buildPetOverview(AIPetContext context) async {
    petOverview = _overviewGenerator(context);

    notifyListeners();
  }

  Future<void> loadContextSummary(AIPetContext context) async {
    isLoading = true;

    notifyListeners();

    petOverview = _overviewGenerator(context);

    healthSummary = _healthSummaryGenerator(context);

    preventiveCare = _preventiveCareGenerator(context);

    vetVisitPrep = _vetPrepGenerator(context);

    isLoading = false;

    notifyListeners();
  }

  bool hasContext() {
    return petOverview != null;
  }
}
