import 'package:flutter/material.dart';

import '../providers/ai_provider.dart';
import '../widgets/chat_bubble.dart';

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
      appBar: AppBar(title: const Text("PetCare AI")),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: provider,
              builder: (_, __) {
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

          AnimatedBuilder(
            animation: provider,
            builder: (_, __) {
              if (!provider.isLoading) {
                return const SizedBox();
              }

              return const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              );
            },
          ),

          SafeArea(
            child: Padding(
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
          ),
        ],
      ),
    );
  }
}
