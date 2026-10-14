import '../entities/ai_response.dart';

abstract class AIRepository {
  Future<AIResponse> askAI(String prompt);

  Future<AIResponse> generateHealthSummary(String petData);

  Future<AIResponse> generateInsights(String petData);

  Future<AIResponse> prepareVetVisit(String petData);
}
