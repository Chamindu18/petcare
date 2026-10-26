import 'package:flutter/foundation.dart';

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
    final normalizedMap = <String, dynamic>{};

    // Normalize Firestore field names so accidental whitespace or
    // invisible spacing does not break field lookup.
    for (final entry in map.entries) {
      normalizedMap[entry.key.trim()] = entry.value;
    }

    debugPrint('SERVICE NORMALIZED MAP: $normalizedMap');

    final serviceId = normalizedMap['serviceId'];
    final hospitalId = normalizedMap['hospitalId'];
    final name = normalizedMap['name'];
    final description = normalizedMap['description'];
    final duration = normalizedMap['duration'];
    final active = normalizedMap['active'];

    debugPrint(
      'SERVICE NORMALIZED VALUES: '
      'serviceId=$serviceId '
      'hospitalId=$hospitalId '
      'name=$name '
      'description=$description '
      'duration=$duration '
      'active=$active',
    );

    if (serviceId is! String ||
        hospitalId is! String ||
        name is! String ||
        description is! String ||
        active is! bool) {
      throw FormatException(
        'Invalid service data: $normalizedMap',
      );
    }

    return ServiceModel(
      serviceId: serviceId,
      hospitalId: hospitalId,
      name: name,
      description: description,
      duration: duration is num ? duration.toInt() : null,
      active: active,
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