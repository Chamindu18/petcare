
import 'ai_message.dart';

class AIConversation {
  const AIConversation({
    required this.conversationId,
    required this.ownerId,
    required this.petId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String conversationId;
  final String ownerId;
  final String petId;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
}
