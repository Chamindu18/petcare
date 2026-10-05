import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class UpdateTreatment {
  const UpdateTreatment(this._repository);

  final TreatmentRepository _repository;

  Future<void> call(Treatment treatment) {
    return _repository.updateTreatment(treatment);
  }
}
