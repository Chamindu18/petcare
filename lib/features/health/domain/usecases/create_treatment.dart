import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class CreateTreatment {
  const CreateTreatment(this._repository);

  final TreatmentRepository _repository;

  Future<Treatment> call(Treatment treatment) {
    return _repository.createTreatment(treatment);
  }
}
