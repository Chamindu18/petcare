import '../../domain/entities/service.dart';

/// Converts Firestore service data into a domain Service.
class ServiceModel extends Service {
  const ServiceModel({
    required super.serviceId,
    required super.hospitalId,
    required super.name,
    required super.description,
    super.duration,
    required super.active,
  });

  /// Creates a ServiceModel from Firestore data.
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      serviceId: map['serviceId'] as String,
      hospitalId: map['hospitalId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      duration: map['duration'] as int?,
      active: map['active'] as bool,
    );
  }

  /// Converts the model into Firestore-compatible data.
  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'hospitalId': hospitalId,
      'name': name,
      'description': description,
      'duration': duration,
      'active': active,
    };
  }
}
