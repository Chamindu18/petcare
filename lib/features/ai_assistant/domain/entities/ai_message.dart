enum AIMessageRole { user, assistant }

class AIMessage {
  const AIMessage({
    required this.messageId,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String messageId;
  final String conversationId;
  final AIMessageRole role;
  final String content;
  final DateTime createdAt;
}
