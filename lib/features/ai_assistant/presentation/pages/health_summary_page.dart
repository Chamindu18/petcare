import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/ai_card.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../domain/entities/ai_pet_context.dart';
import '../../domain/usecases/generate_pet_overview.dart';
import '../../domain/usecases/format_pet_context.dart';

class HealthSummaryPage extends StatefulWidget {
  const HealthSummaryPage({super.key, this.contextData});

  final AIPetContext? contextData;

  @override
  State<HealthSummaryPage> createState() => _HealthSummaryPageState();
}

class _HealthSummaryPageState extends State<HealthSummaryPage> {
  final AIProvider provider = AIProvider();

  final GeneratePetOverview _overviewGenerator = const GeneratePetOverview();
  final FormatPetContext _formatter = const FormatPetContext();
  @override
  void initState() {
    super.initState();

    if (widget.contextData == null) {
      provider.generateHealthSummary();
    } else {
      provider.loadContextSummary(widget.contextData!);
    }
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

              if (widget.contextData == null) {
                return SingleChildScrollView(
                  child: AICard(
                    title: 'Pet Health Summary',
                    content: provider.healthSummary,
                  ),
                );
              }

              final overview = _overviewGenerator(widget.contextData!);
              final formattedContext = _formatter(widget.contextData!);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    AICard(
                      title: '${widget.contextData!.pet.name} Health Summary',
                      content: provider.healthSummary,
                    ),

                    AICard(title: 'Pet Overview', content: formattedContext),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
