import '../entities/ai_response.dart';
import '../repositories/ai_repository.dart';

class GenerateInsights {
  final AIRepository repository;

  GenerateInsights(this.repository);

  Future<AIResponse> call(String petData) {
    return repository.generateInsights(petData);
  }
}
