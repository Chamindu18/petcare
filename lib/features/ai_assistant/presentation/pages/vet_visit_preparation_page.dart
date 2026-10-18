import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/ai_card.dart';

class VetVisitPreparationPage extends StatefulWidget {
  const VetVisitPreparationPage({super.key});

  @override
  State<VetVisitPreparationPage> createState() =>
      _VetVisitPreparationPageState();
}

class _VetVisitPreparationPageState extends State<VetVisitPreparationPage> {
  final AIProvider provider = AIProvider();

  @override
  void initState() {
    super.initState();

    provider.generateVetVisitPrep();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Visit Preparation')),
      body: AnimatedBuilder(
        animation: provider,
        builder: (context, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: AICard(
              title: 'Vet Visit Preparation',
              content: provider.vetVisitPrep,
            ),
          );
        },
      ),
    );
  }
}
