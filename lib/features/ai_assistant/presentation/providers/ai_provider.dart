import 'package:flutter/material.dart';

import '../../domain/entities/ai_message.dart';
import '../../../pets/domain/entities/pet.dart';

class AIProvider extends ChangeNotifier {
  bool isLoading = false;

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
}
