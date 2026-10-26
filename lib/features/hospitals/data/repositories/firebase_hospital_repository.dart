import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/hospital.dart';
import '../../domain/repositories/hospital_repository.dart';
import '../models/hospital_model.dart';

/// Firebase implementation of the hospital repository.
class FirebaseHospitalRepository implements HospitalRepository {
  FirebaseHospitalRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _hospitalsCollection =>
      _firestore.collection('hospitals');

  @override
  Future<List<Hospital>> getHospitals() async {
    // Only active hospitals are shown to pet owners.
    final snapshot = await _hospitalsCollection
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((document) => HospitalModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<Hospital?> getHospitalById(String hospitalId) async {
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