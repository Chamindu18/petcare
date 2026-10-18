import 'package:flutter/material.dart';

import '../../domain/entities/ai_message.dart';

class AIProvider extends ChangeNotifier {
  bool isLoading = false;

  final List<AIMessage> messages = [];

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(AIMessage(message: text, isUser: true));

    notifyListeners();

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    messages.add(
      AIMessage(
        message: "This is a sample AI response for: $text",
        isUser: false,
      ),
    );

    isLoading = false;

    notifyListeners();
  }
}
