import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/hospital.dart';
import '../../domain/repositories/hospital_repository.dart';
import '../models/hospital_model.dart';

/// Reads hospital data from Firestore.
class FirebaseHospitalRepository implements HospitalRepository {
  FirebaseHospitalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Reference to the hospitals collection.
  CollectionReference<Map<String, dynamic>> get _hospitalsCollection =>
      _firestore.collection('hospitals');

  @override
  Future<List<Hospital>> getHospitals() async {
    // Only show hospitals marked as active.
    final snapshot = await _hospitalsCollection
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((document) => HospitalModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<Hospital?> getHospitalById(String hospitalId) async {
    // Get one hospital using its Firestore document ID.
    final document = await _hospitalsCollection.doc(hospitalId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['active'] != true) {
      return null;
    }

    return HospitalModel.fromMap(data);
  }
}
