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
${contextData.pet.name} currently has:

• ${contextData.conditions.length} medical conditions
• ${contextData.vaccinations.length} vaccinations
• ${contextData.treatments.length} treatments
• ${contextData.measurements.length} health measurements
''';
    }

    if (q.contains('vaccination')) {
      return '''
${contextData.pet.name} has
${contextData.vaccinations.length}
recorded vaccinations.
''';
    }

    if (q.contains('condition')) {
      return '''
${contextData.pet.name} has
${contextData.conditions.length}
recorded medical conditions.
''';
    }

    if (q.contains('treatment')) {
      return '''
${contextData.pet.name} has
${contextData.treatments.length}
recorded treatments.
''';
    }

    if (q.contains('vet')) {
      return '''
        Suggested vet discussion topics:

        • Medical conditions

        • Vaccination history

        • Treatments

        • Recent measurements
        ''';
    }

    return '''
I can help with:

• Health Summary

• Vaccinations

• Conditions

• Treatments

• Vet Visit Preparation
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
                        'Selected Pet: ${widget.contextData!.pet.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.contextData!.conditions.length} Conditions • '
                        '${widget.contextData!.vaccinations.length} Vaccinations • '
                        '${widget.contextData!.treatments.length} Treatments',
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SuggestionChip(
                        label: 'Health',
                        prompt: 'Give me pet health advice',
                        controller: controller,
                      ),
                      const SizedBox(width: 8),

                      _SuggestionChip(
                        label: 'Nutrition',
                        prompt: 'Tell me about pet nutrition',
                        controller: controller,
                      ),
                      const SizedBox(width: 8),

                      _SuggestionChip(
                        label: 'Behavior',
                        prompt: 'Help me understand pet behavior',
                        controller: controller,
                      ),
                      const SizedBox(width: 8),

                      _SuggestionChip(
                        label: 'General',
                        prompt: 'General pet care tips',
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
