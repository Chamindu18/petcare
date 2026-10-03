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

  factory AdoptionListingModel.fromEntity(AdoptionListing listing) {
    return AdoptionListingModel(
      listingId: listing.listingId,
      providerId: listing.providerId,
      petName: listing.petName,
      species: listing.species,
      breed: listing.breed,
      ageDescription: listing.ageDescription,
      gender: listing.gender,
      description: listing.description,
      location: listing.location,
      imageAsset: listing.imageAsset,
      status: listing.status,
      contactNote: listing.contactNote,
      createdAt: listing.createdAt,
      updatedAt: listing.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'petName': petName,
      'species': species,
      if (breed != null && breed!.trim().isNotEmpty) 'breed': breed,
      if (ageDescription != null && ageDescription!.trim().isNotEmpty)
        'ageDescription': ageDescription,
      'gender': gender,
      'description': description,
      'location': location,
      if (imageAsset != null && imageAsset!.trim().isNotEmpty)
        'imageAsset': imageAsset,
      'status': status,
      if (contactNote != null && contactNote!.trim().isNotEmpty)
        'contactNote': contactNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
