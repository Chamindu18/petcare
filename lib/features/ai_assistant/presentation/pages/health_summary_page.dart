import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/ai_card.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../domain/entities/ai_pet_context.dart';

class HealthSummaryPage extends StatefulWidget {
  const HealthSummaryPage({super.key, this.contextData});

  final AIPetContext? contextData;

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
      body: Stack(
        children: [
          const Positioned.fill(child: PetCareBackground()),

          AnimatedBuilder(
            animation: provider,
            builder: (context, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                child: AICard(
                  title: widget.contextData == null
                      ? 'Pet Health Summary'
                      : '${widget.contextData!.pet.name} Health Summary',
                  content: provider.healthSummary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
