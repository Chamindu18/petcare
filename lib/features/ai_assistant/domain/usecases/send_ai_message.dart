import '../entities/ai_message.dart';
import '../repositories/ai_repository.dart';

class SendAIMessage {
  const SendAIMessage(this._repository);

  final AIRepository _repository;

  Future<AIMessage> call({
    required String conversationId,
    required String content,
    required String petContext,
  }) async {
    if (conversationId.trim().isEmpty) {
      throw ArgumentError.value(
        conversationId,
        'conversationId',
        'Conversation ID cannot be empty.',
      );
    }

    final message = content.trim();

    if (message.isEmpty) {
      throw ArgumentError.value(content, 'content', 'Message cannot be empty.');
    }

    final context = petContext.trim();

    if (context.isEmpty) {
      throw ArgumentError.value(
        petContext,
        'petContext',
        'Pet context cannot be empty.',
      );
    }

    return _repository.sendMessage(
      conversationId: conversationId,
      content: message,
      petContext: context,
    );
  }
}
