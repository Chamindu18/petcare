import '../entities/health_measurement.dart';

abstract interface class HealthMeasurementRepository {
  Future<HealthMeasurement> createHealthMeasurement(
    HealthMeasurement measurement,
  );

  Future<List<HealthMeasurement>> getHealthMeasurements(String petId);

  Future<HealthMeasurement?> getHealthMeasurementById(
    String petId,
    String measurementId,
  );

  Future<void> updateHealthMeasurement(HealthMeasurement measurement);

  Future<void> deleteHealthMeasurement(String petId, String measurementId);
}
