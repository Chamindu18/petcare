import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../models/service_model.dart';

/// Reads hospital service data from Firestore.
class FirebaseServiceRepository implements ServiceRepository {
  FirebaseServiceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Reference to the services collection.
  CollectionReference<Map<String, dynamic>> get _servicesCollection =>
      _firestore.collection('services');

  @override
  Future<List<Service>> getServicesByHospital(String hospitalId) async {
    // Only return active services for the selected hospital.
    final snapshot = await _servicesCollection
        .where('hospitalId', isEqualTo: hospitalId)
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((document) => ServiceModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<Service?> getServiceById(String serviceId) async {
    // Get one service using its Firestore document ID.
    final document = await _servicesCollection.doc(serviceId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['active'] != true) {
      return null;
    }

    return ServiceModel.fromMap(data);
  }
}
