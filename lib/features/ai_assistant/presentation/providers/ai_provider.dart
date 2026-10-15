import 'package:flutter/material.dart';

class AIProvider extends ChangeNotifier {
  bool isLoading = false;

  String aiResponse = '';

  Future<void> sendMessage(String message) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    aiResponse = "This is a dummy AI response.";

    isLoading = false;
    notifyListeners();
  }
}
