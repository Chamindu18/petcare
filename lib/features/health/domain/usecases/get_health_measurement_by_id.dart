import '../entities/health_measurement.dart';
import '../repositories/health_measurement_repository.dart';

class GetHealthMeasurementById {
  const GetHealthMeasurementById(this._repository);

  final HealthMeasurementRepository _repository;

  Future<HealthMeasurement?> call(String petId, String measurementId) {
    return _repository.getHealthMeasurementById(petId, measurementId);
  }
}
