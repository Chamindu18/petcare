import '../entities/health_measurement.dart';
import '../repositories/health_measurement_repository.dart';

class GetHealthMeasurements {
  const GetHealthMeasurements(this._repository);

  final HealthMeasurementRepository _repository;

  Future<List<HealthMeasurement>> call(String petId) {
    return _repository.getHealthMeasurements(petId);
  }
}
