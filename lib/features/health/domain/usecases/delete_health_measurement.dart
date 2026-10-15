import '../repositories/health_measurement_repository.dart';

class DeleteHealthMeasurement {
  const DeleteHealthMeasurement(this._repository);

  final HealthMeasurementRepository _repository;

  Future<void> call(String petId, String measurementId) {
    return _repository.deleteHealthMeasurement(petId, measurementId);
  }
}
