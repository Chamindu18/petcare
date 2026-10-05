import '../entities/health_measurement.dart';
import '../repositories/health_measurement_repository.dart';

class UpdateHealthMeasurement {
  const UpdateHealthMeasurement(this._repository);

  final HealthMeasurementRepository _repository;

  Future<void> call(HealthMeasurement measurement) {
    return _repository.updateHealthMeasurement(measurement);
  }
}
