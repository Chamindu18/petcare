import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/adoption_listing.dart';

class AdoptionListingModel extends AdoptionListing {
  const AdoptionListingModel({
    required super.listingId,
    required super.providerId,
    required super.petName,
    required super.species,
    super.breed,
    super.ageDescription,
    required super.gender,
    required super.description,
    required super.location,
    super.imageAsset,
    required super.status,
    super.contactNote,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdoptionListingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Adoption listing document does not exist.');
    }

    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    if (createdAt is! Timestamp) {
      throw StateError('Adoption listing createdAt is invalid.');
    }

    if (updatedAt is! Timestamp) {
      throw StateError('Adoption listing updatedAt is invalid.');
    }

    return AdoptionListingModel(
      listingId: document.id,
      providerId: data['providerId'] as String,
      petName: data['petName'] as String,
      species: data['species'] as String,
      breed: data['breed'] as String?,
      ageDescription: data['ageDescription'] as String?,
      gender: data['gender'] as String,
      description: data['description'] as String,
      location: data['location'] as String,
      imageAsset: data['imageAsset'] as String?,
      status: data['status'] as String,
      contactNote: data['contactNote'] as String?,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }
}
