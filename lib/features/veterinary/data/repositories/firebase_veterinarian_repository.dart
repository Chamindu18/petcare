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
  Future<List<Veterinarian>> getVeterinarians() async {
    // Doctor discovery only shows active veterinarians.
    final snapshot = await _veterinariansCollection
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (document) => VeterinarianModel.fromMap({
            ...document.data(),
            'vetId': document.id,
          }),
        )
        .toList();
  }

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
        .map(
          (document) => VeterinarianModel.fromMap({
            ...document.data(),
            'vetId': document.id,
          }),
        )
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

    return VeterinarianModel.fromMap({...data, 'vetId': document.id});
  }

  @override
  Future<void> updateVeterinarianProfile({
    required String vetId,
    required String name,
    String? profileImageUrl,
    String? specialty,
    String? qualifications,
    int? experienceYears,
    String? bio,
  }) async {
    if (vetId.trim().isEmpty) {
      throw const VeterinarianRepositoryException(
        'A valid veterinarian ID is required.',
      );
    }

    await _veterinariansCollection.doc(vetId.trim()).update({
      'name': name.trim(),
      'profileImageUrl': _normalize(profileImageUrl),
      'specialty': _normalize(specialty),
      'qualifications': _normalize(qualifications),
      'experienceYears': experienceYears,
      'bio': _normalize(bio),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();

    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class VeterinarianRepositoryException implements Exception {
  const VeterinarianRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
