import '../entities/ai_conversation.dart';
import '../entities/ai_message.dart';

abstract class AIRepository {
  Future<AIConversation> createConversation({
    required String ownerId,
    required String petId,
  });

  Future<AIConversation?> getConversation({
    required String conversationId,
  });

  Stream<List<AIConversation>> watchConversations({
    required String ownerId,
    required String petId,
  });

  Future<AIMessage> sendMessage({
    required String conversationId,
    required String content,
    required String petContext,
  });
}