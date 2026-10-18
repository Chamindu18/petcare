import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/chat_bubble.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../../../app/theme/app_theme.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController controller = TextEditingController();

  final AIProvider provider = AIProvider();

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
                        provider.sendMessage(controller.text);

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
