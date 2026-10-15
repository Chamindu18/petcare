import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/veterinarian.dart';
import '../../domain/repositories/veterinarian_repository.dart';
import '../models/veterinarian_model.dart';

/// Reads veterinarian data from Firestore.
class FirebaseVeterinarianRepository implements VeterinarianRepository {
  FirebaseVeterinarianRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Reference to the veterinarians collection.
  CollectionReference<Map<String, dynamic>> get _veterinariansCollection =>
      _firestore.collection('veterinarians');

  @override
  Future<List<Veterinarian>> getVeterinariansByHospital(
    String hospitalId,
  ) async {
    // Get only active veterinarians from the selected hospital.
    final snapshot = await _veterinariansCollection
        .where('hospitalId', isEqualTo: hospitalId)
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((document) => VeterinarianModel.fromMap(document.data()))
        .toList();
  }

  @override
  Future<Veterinarian?> getVeterinarianById(String vetId) async {
    // Get one veterinarian using the Firestore document ID.
    final document = await _veterinariansCollection.doc(vetId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null || data['active'] != true) {
      return null;
    }

    return VeterinarianModel.fromMap(data);
  }
}
