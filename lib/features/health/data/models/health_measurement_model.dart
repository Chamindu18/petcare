import '../../domain/entities/health_measurement.dart';
import 'stored_health_date.dart';

class HealthMeasurementModel extends HealthMeasurement {
  const HealthMeasurementModel({
    required super.measurementId,
    required super.petId,
    required super.type,
    required super.value,
    required super.unit,
    required super.recordedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  static HealthMeasurementModel? tryFromMap(Map<String, dynamic> map) {
    final recordedAt = parseStoredHealthDate(map['recordedAt']);
    final createdAt = parseStoredHealthDate(map['createdAt']);
    final updatedAt = parseStoredHealthDate(map['updatedAt']);
    if (recordedAt == null || createdAt == null || updatedAt == null) {
      return null;
    }
    return HealthMeasurementModel(
      measurementId: map['measurementId'] as String,
      petId: map['petId'] as String,
      type: map['type'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      recordedAt: recordedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory HealthMeasurementModel.fromEntity(HealthMeasurement measurement) {
    return HealthMeasurementModel(
      measurementId: measurement.measurementId,
      petId: measurement.petId,
      type: measurement.type,
      value: measurement.value,
      unit: measurement.unit,
      recordedAt: measurement.recordedAt,
      createdAt: measurement.createdAt,
      updatedAt: measurement.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'measurementId': measurementId,
      'petId': petId,
      'type': type,
      'value': value,
      'unit': unit,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
