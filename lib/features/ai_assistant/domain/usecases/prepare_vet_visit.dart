import '../entities/ai_response.dart';
import '../repositories/ai_repository.dart';

class PrepareVetVisit {
  final AIRepository repository;

  PrepareVetVisit(this.repository);

  Future<AIResponse> call(String petData) {
    return repository.prepareVetVisit(petData);
  }
}
