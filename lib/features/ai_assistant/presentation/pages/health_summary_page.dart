import 'package:flutter/material.dart';

class HealthSummaryPage extends StatelessWidget {
  const HealthSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Summary')),
      body: const Center(child: Text('Health Summary Screen')),
    );
  }
}
