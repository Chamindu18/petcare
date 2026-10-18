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
HEALTH STATUS

🟢 Good

SUMMARY

• Vaccinations are up to date

• No active conditions

• Stable weight

RECOMMENDATION

Continue regular wellness monitoring.
''';

    isLoading = false;
    notifyListeners();
  }

  Future<void> generatePreventiveCare() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    preventiveCare = '''
PRIORITY RECOMMENDATIONS

• Annual vaccination review

• Monthly weight monitoring

• Dental health checks

• Maintain exercise routine

NEXT ACTION

Schedule a wellness visit within the next few months.
''';

    isLoading = false;
    notifyListeners();
  }

  Future<void> generateVetVisitPrep() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    vetVisitPrep = '''
DISCUSSION POINTS

1. Are vaccinations current?

2. Is the diet still appropriate?

3. Is the pet's weight healthy?

4. Are any screenings recommended?

BRING TO THE VISIT

• Vaccination records

• Treatment history

• Recent observations or concerns
''';

    isLoading = false;
    notifyListeners();
  }
}
