import 'package:flutter/material.dart';
import 'package:petcare/features/health/presentation/providers/health_controller.dart';

import '../providers/ai_provider.dart';
import '../widgets/chat_bubble.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../../../app/theme/app_theme.dart';

import '../../domain/entities/ai_pet_context.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../domain/usecases/create_pet_context.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({
    super.key,
    this.contextData,
    this.pets,
    this.healthController,
  });

  final AIPetContext? contextData;
  final List<Pet>? pets;
  final HealthController? healthController;

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController controller = TextEditingController();

  final AIProvider provider = AIProvider();
  final ScrollController _scrollController = ScrollController();
  AIPetContext? _activeContext;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _generateResponse(String question) {
    final contextData = _activeContext;

    if (contextData == null) {
      return '''
⚠️ No Pet Selected

Please select a pet first.
''';
    }

    final q = question.toLowerCase();

    if (q.contains('summary')) {
      return '''
        📄 Spiderman Health Summary

        📋 Conditions: ${contextData.conditions.length}

        💉 Vaccinations: ${contextData.vaccinations.length}

        💊 Treatments: ${contextData.treatments.length}

        📈 Measurements: ${contextData.measurements.length}

        ✅ Recommendation

        Continue routine health monitoring and maintain vaccination schedules.
        ''';
    }

    if (q.contains('condition')) {
      if (contextData.conditions.isEmpty) {
        return '${contextData.pet.name} has no recorded medical conditions.';
      }

      final conditions = contextData.conditions
          .take(5)
          .map((c) => '• ${c.name} (${c.status})')
          .join('\n');

      return '''
        📋 Medical Conditions

        $conditions

        ✅ Advice

        Review active conditions regularly and continue recommended treatments.
        ''';
    }

    if (q.contains('vaccination')) {
      if (contextData.vaccinations.isEmpty) {
        return '${contextData.pet.name} has no recorded vaccinations.';
      }

      final vaccinations = contextData.vaccinations
          .take(5)
          .map((v) => '• ${v.name}')
          .join('\n');

      return '''
        💉 Vaccination History

        $vaccinations

        📊 Total Vaccinations:
        ${contextData.vaccinations.length}

        ✅ Reminder

        Keep vaccination schedules up to date.
        ''';
    }

    if (q.contains('treatment')) {
      if (contextData.treatments.isEmpty) {
        return '${contextData.pet.name} has no recorded treatments.';
      }

      final treatments = contextData.treatments
          .take(5)
          .map((t) => '• ${t.name} (${t.status})')
          .join('\n');

      return '''
        💊 Treatment Records

        $treatments

        📊 Active Medical Care

        Continue monitoring treatment progress and consult a veterinarian when necessary.
        ''';
    }

    if (q.contains('measurement')) {
      return '''
      ${contextData.pet.name} has
      ${contextData.measurements.length}
      health measurements recorded.
      ''';
    }

    if (q.contains('vet')) {
      return '''
        🩺 Vet Visit Preparation

        Topics to discuss:

        • Medical conditions

        • Vaccination history

        • Ongoing treatments

        • Recent health measurements

        ✅ Bring any recent observations or concerns to the appointment.
        ''';
    }

    if (q.contains('preventive')) {
      return '''
          Preventive Care Overview

          💉 Vaccinations:
          ${contextData.vaccinations.length}

          📋 Conditions:
          ${contextData.conditions.length}

          💊 Treatments:
          ${contextData.treatments.length}

          Recommendations:

          • Keep vaccinations up to date

          • Monitor health changes regularly

          • Record treatment progress

          • Schedule regular vet checkups
          ''';
    }

    if (q.contains('vet advice')) {
      return '''
        🩺 Vet Visit Preparation

        Topics to discuss:

        • Medical conditions

        • Vaccination history

        • Ongoing treatments

        • Recent health measurements

        ✅ Bring any recent observations or concerns to the appointment.
        ''';
    }
    return '''
              I can help with:

              • summary

              • conditions

              • vaccinations

              • treatments

              • measurements

              • preventive care

              • vet advice

              Try typing one of the above.
              ''';
  }

  @override
  void initState() {
    super.initState();

    _activeContext = widget.contextData;
  }

  final CreatePetContext _createPetContext = const CreatePetContext();
  Future<void> _selectPet(Pet pet) async {
    if (widget.healthController == null) {
      return;
    }

    await widget.healthController!.loadHealthRecords(pet.petId);

    final context = _createPetContext(
      pet: pet,
      conditions: widget.healthController!.medicalConditions,
      vaccinations: widget.healthController!.vaccinations,
      treatments: widget.healthController!.treatments,
      measurements: widget.healthController!.healthMeasurements,
    );

    setState(() {
      _activeContext = context;
    });

    provider.addAssistantMessage(
      ' ${pet.name} selected. You can now ask me about health records, vaccinations, treatments, and vet preparation.',
    );
    _scrollToBottom();
    provider.addAssistantMessage('${pet.name} selected...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetCare AI')),
      body: Stack(
        children: [
          const Positioned.fill(child: PetCareBackground()),

          Column(
            children: [
              if (_activeContext != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🐾 ${_activeContext!.pet.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        '📋 ${_activeContext!.conditions.length} Conditions   '
                        '💉 ${_activeContext!.vaccinations.length} Vaccinations   '
                        '💊 ${_activeContext!.treatments.length} Treatments',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_activeContext == null &&
                  widget.pets != null &&
                  widget.pets!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select a Pet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.pets!
                            .map(
                              (pet) => ActionChip(
                                avatar: const Icon(Icons.pets),
                                label: Text(pet.name),
                                onPressed: () async {
                                  await _selectPet(pet);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: AnimatedBuilder(
                  animation: provider,
                  builder: (_, _) {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final message = provider.messages[index];

                        return ChatBubble(
                          message: message.message,
                          isUser: message.isUser,
                        );
                      },
                    );
                  },
                ),
              ),

              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SuggestionChip(
                        label: 'Summary',
                        prompt: 'summary',
                        controller: controller,
                      ),
                      const SizedBox(width: 8),

                      _SuggestionChip(
                        label: 'Vaccinations',
                        prompt: 'vaccinations',
                        controller: controller,
                      ),
                      const SizedBox(width: 8),

                      _SuggestionChip(
                        label: 'Conditions',
                        prompt: 'conditions',
                        controller: controller,
                      ),
                      const SizedBox(width: 8),

                      _SuggestionChip(
                        label: 'Vet Advice',
                        prompt: 'vet advice',
                        controller: controller,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Ask something...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        final question = controller.text.trim();

                        if (question.isEmpty) {
                          return;
                        }

                        provider.addUserMessage(question);

                        provider.addAssistantMessage(
                          _generateResponse(question),
                        );

                        controller.clear();

                        _scrollToBottom();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.prompt,
    required this.controller,
  });

  final String label;
  final String prompt;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppTheme.primary),
      label: Text(label),
      onPressed: () {
        controller.text = prompt;
      },
    );
  }
}
