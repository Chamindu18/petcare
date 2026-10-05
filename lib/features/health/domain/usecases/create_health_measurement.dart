import '../entities/health_measurement.dart';
import '../repositories/health_measurement_repository.dart';

class CreateHealthMeasurement {
  const CreateHealthMeasurement(this._repository);

  final HealthMeasurementRepository _repository;

  Future<HealthMeasurement> call(HealthMeasurement measurement) {
    return _repository.createHealthMeasurement(measurement);
  }
}
