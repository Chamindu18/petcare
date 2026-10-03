class HealthMeasurement {
  const HealthMeasurement({
    required this.measurementId,
    required this.petId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String measurementId;
  final String petId;

  /// Type of measurement, such as weight or temperature.
  final String type;

  /// Recorded measurement value.
  final double value;

  /// Unit used for the measurement.
  final String unit;

  /// Date and time the measurement was recorded.
  final DateTime recordedAt;

  final DateTime createdAt;
  final DateTime updatedAt;
}
