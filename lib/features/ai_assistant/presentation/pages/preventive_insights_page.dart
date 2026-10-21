import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/ai_card.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../domain/entities/ai_pet_context.dart';
import '../../domain/usecases/generate_pet_overview.dart';

class PreventiveInsightsPage extends StatefulWidget {
  const PreventiveInsightsPage({super.key, this.contextData});

  final AIPetContext? contextData;

  @override
  State<PreventiveInsightsPage> createState() => _PreventiveInsightsPageState();
}

class _PreventiveInsightsPageState extends State<PreventiveInsightsPage> {
  final AIProvider provider = AIProvider();
  final GeneratePetOverview _overviewGenerator = const GeneratePetOverview();

  @override
  void initState() {
    super.initState();

    provider.generatePreventiveCare();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preventive Care')),
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
                    title: 'Preventive Care Tips',
                    content: provider.preventiveCare,
                  ),
                );
              }

              final overview = _overviewGenerator(widget.contextData!);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    AICard(
                      title: '${widget.contextData!.pet.name} Preventive Care',
                      content: provider.preventiveCare,
                    ),

                    AICard(
                      title: 'Health Record Overview',
                      content:
                          '''
                            Conditions: ${overview['conditionCount']}

                            Vaccinations: ${overview['vaccinationCount']}

                            Treatments: ${overview['treatmentCount']}

                            Measurements: ${overview['measurementCount']}
                            ''',
                    ),
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
