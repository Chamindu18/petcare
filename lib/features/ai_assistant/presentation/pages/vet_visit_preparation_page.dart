import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/ai_card.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../domain/entities/ai_pet_context.dart';
import '../../domain/usecases/generate_pet_overview.dart';

class VetVisitPreparationPage extends StatefulWidget {
  const VetVisitPreparationPage({super.key, this.contextData});

  final AIPetContext? contextData;

  @override
  State<VetVisitPreparationPage> createState() =>
      _VetVisitPreparationPageState();
}

class _VetVisitPreparationPageState extends State<VetVisitPreparationPage> {
  final AIProvider provider = AIProvider();
  final GeneratePetOverview _overviewGenerator = const GeneratePetOverview();
  @override
  void initState() {
    super.initState();

    provider.generateVetVisitPrep();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Visit Preparation')),
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
                    title: 'Vet Visit Preparation',
                    content: provider.vetVisitPrep,
                  ),
                );
              }

              final overview = _overviewGenerator(widget.contextData!);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    AICard(
                      title:
                          '${widget.contextData!.pet.name} Vet Visit Preparation',
                      content: provider.vetVisitPrep,
                    ),

                    AICard(
                      title: 'Appointment Discussion Overview',
                      content:
                          '''
                          Pet Name: ${overview['petName']}

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
