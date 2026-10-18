import 'package:flutter/material.dart';

import '../../domain/entities/ai_message.dart';

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
Pet Health Summary

• Vaccinations are up to date

• No active medical conditions recorded

• Pet weight remains stable

• Overall health status: Good
''';

    isLoading = false;
    notifyListeners();
  }

  Future<void> generatePreventiveCare() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    preventiveCare = '''
Preventive Care Tips

• Annual vaccination review

• Monthly weight monitoring

• Daily exercise recommended

• Regular dental checks
''';

    isLoading = false;
    notifyListeners();
  }

  Future<void> generateVetVisitPrep() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    vetVisitPrep = '''
Suggested Questions

1. Are all vaccinations current?

2. Is the current diet suitable?

3. Any signs of health concerns?

4. What preventive checks are recommended?
''';

    isLoading = false;
    notifyListeners();
  }
}
