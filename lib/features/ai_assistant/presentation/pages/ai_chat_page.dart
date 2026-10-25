import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/chat_bubble.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../../../app/theme/app_theme.dart';

import '../../domain/entities/ai_pet_context.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key, this.contextData});

  final AIPetContext? contextData;

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController controller = TextEditingController();

  final AIProvider provider = AIProvider();
  String _generateResponse(String question) {
    final contextData = widget.contextData;

    if (contextData == null) {
      return 'Please select a pet first.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetCare AI')),
      body: Stack(
        children: [
          const Positioned.fill(child: PetCareBackground()),

          Column(
            children: [
              if (widget.contextData != null)
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
                        widget.contextData!.pet.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.contextData!.pet.species} • '
                        '${widget.contextData!.pet.breed}',
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: AnimatedBuilder(
                  animation: provider,
                  builder: (_, _) {
                    return ListView.builder(
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
