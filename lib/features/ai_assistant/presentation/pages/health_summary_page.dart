import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/ai_card.dart';

class HealthSummaryPage extends StatefulWidget {
  const HealthSummaryPage({super.key});

  @override
  State<HealthSummaryPage> createState() => _HealthSummaryPageState();
}

class _HealthSummaryPageState extends State<HealthSummaryPage> {
  final AIProvider provider = AIProvider();

  @override
  void initState() {
    super.initState();

    provider.generateHealthSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Summary')),
      body: AnimatedBuilder(
        animation: provider,
        builder: (context, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: AICard(
              title: 'Pet Health Summary',
              content: provider.healthSummary,
            ),
          );
        },
      ),
    );
  }
}
