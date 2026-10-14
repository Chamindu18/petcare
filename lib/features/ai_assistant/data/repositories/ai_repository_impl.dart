import '../../domain/entities/ai_response.dart';
import '../../domain/repositories/ai_repository.dart';

class AIRepositoryImpl implements AIRepository {
  @override
  Future<AIResponse> askAI(String prompt) async {
    return AIResponse(response: 'This is a dummy AI response.');
  }

  @override
  Future<AIResponse> generateHealthSummary(String petData) async {
    return AIResponse(response: 'Health summary will appear here.');
  }

  @override
  Future<AIResponse> generateInsights(String petData) async {
    return AIResponse(response: 'Preventive insights will appear here.');
  }

  @override
  Future<AIResponse> prepareVetVisit(String petData) async {
    return AIResponse(response: 'Vet visit preparation will appear here.');
  }
}
