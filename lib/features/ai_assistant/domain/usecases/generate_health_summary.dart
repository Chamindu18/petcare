import '../entities/ai_response.dart';
import '../repositories/ai_repository.dart';

class GenerateHealthSummary {
  final AIRepository repository;

  GenerateHealthSummary(this.repository);

  Future<AIResponse> call(String petData) {
    return repository.generateHealthSummary(petData);
  }
}
