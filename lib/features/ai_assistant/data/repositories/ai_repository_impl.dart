import '../../domain/repositories/ai_repository.dart';
import '../../domain/entities/ai_response.dart';

class AIRepositoryImpl implements AIRepository {
  @override
  Future<AIResponse> askAI(String prompt) async {
    throw UnsupportedError('Live AI responses are not configured.');
  }

  @override
  Future<AIResponse> generateHealthSummary(String petData) async {
    throw UnsupportedError('Live AI health summaries are not configured.');
  }

  @override
  Future<AIResponse> generateInsights(String petData) async {
    throw UnsupportedError('Live AI insights are not configured.');
  }

  @override
  Future<AIResponse> prepareVetVisit(String petData) async {
    throw UnsupportedError('Live AI visit preparation is not configured.');
  }
}
