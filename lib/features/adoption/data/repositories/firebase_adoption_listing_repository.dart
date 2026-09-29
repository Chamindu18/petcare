import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/adoption_listing.dart';
import '../../domain/repositories/adoption_listing_repository.dart';
import '../models/adoption_listing_model.dart';

class FirebaseAdoptionListingRepository implements AdoptionListingRepository {
  FirebaseAdoptionListingRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _listingsCollection =>
      _firestore.collection('adoption_listings');

  void _ensureSignedIn() {
    if (_auth.currentUser == null) {
      throw const AdoptionListingRepositoryException(
        'You must be signed in to view adoption listings.',
      );
    }
  }

  @override
  Future<AdoptionListing> createListing(AdoptionListing listing) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const AdoptionListingRepositoryException(
        'You must be signed in to create an adoption listing.',
      );
    }

    final document = _listingsCollection.doc();

    final persistedListing = AdoptionListing(
      listingId: document.id,
      providerId: user.uid,
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

    final listingModel = AdoptionListingModel.fromEntity(persistedListing);

    await document.set(listingModel.toMap());

    return persistedListing;
  }

  @override
  Future<void> updateListing(AdoptionListing listing) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const AdoptionListingRepositoryException(
        'You must be signed in to update an adoption listing.',
      );
    }

    final document = await _listingsCollection.doc(listing.listingId).get();

    if (!document.exists) {
      throw const AdoptionListingRepositoryException(
        'Adoption listing was not found.',
      );
    }

    final existingData = document.data();

    if (existingData == null || existingData['providerId'] != user.uid) {
      throw const AdoptionListingRepositoryException(
        'You are not authorized to update this adoption listing.',
      );
    }

    final persistedListing = AdoptionListing(
      listingId: listing.listingId,
      providerId: user.uid,
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

    final listingModel = AdoptionListingModel.fromEntity(persistedListing);

    await document.reference.update(listingModel.toMap());
  }

  @override
  Stream<List<AdoptionListing>> watchAvailableListings() {
    try {
      _ensureSignedIn();
    } catch (error) {
      return Stream.error(error);
    }

    return _listingsCollection
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AdoptionListingModel.fromFirestore).toList(),
        );
  }

  @override
  Stream<List<AdoptionListing>> watchMyListings() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        const AdoptionListingRepositoryException(
          'You must be signed in to view your adoption listings.',
        ),
      );
    }

    return _listingsCollection
        .where('providerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AdoptionListingModel.fromFirestore).toList(),
        );
  }

  @override
  Stream<AdoptionListing?> watchListing({required String listingId}) {
    try {
      _ensureSignedIn();
    } catch (error) {
      return Stream.error(error);
    }

    return _listingsCollection.doc(listingId).snapshots().map((document) {
      if (!document.exists) {
        return null;
      }

      return AdoptionListingModel.fromFirestore(document);
    });
  }
}

class AdoptionListingRepositoryException implements Exception {
  const AdoptionListingRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
