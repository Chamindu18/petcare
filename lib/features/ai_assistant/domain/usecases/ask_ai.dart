import '../entities/ai_response.dart';
import '../repositories/ai_repository.dart';

class AskAI {
  final AIRepository repository;

  AskAI(this.repository);

  Future<AIResponse> call(String prompt) {
    return repository.askAI(prompt);
  }
}
