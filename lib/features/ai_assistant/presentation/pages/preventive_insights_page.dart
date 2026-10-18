import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/ai_card.dart';

class PreventiveInsightsPage extends StatefulWidget {
  const PreventiveInsightsPage({super.key});

  @override
  State<PreventiveInsightsPage> createState() => _PreventiveInsightsPageState();
}

class _PreventiveInsightsPageState extends State<PreventiveInsightsPage> {
  final AIProvider provider = AIProvider();

  @override
  void initState() {
    super.initState();

    provider.generatePreventiveCare();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preventive Care')),
      body: AnimatedBuilder(
        animation: provider,
        builder: (context, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: AICard(
              title: 'Preventive Care Tips',
              content: provider.preventiveCare,
            ),
          );
        },
      ),
    );
  }
}
