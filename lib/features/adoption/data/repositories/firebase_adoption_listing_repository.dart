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

  Future<String> _roleFor(String uid) async {
    final profile = await _firestore.collection('users').doc(uid).get();
    final role = profile.data()?['role'];
    if (role is! String ||
        (role != 'owner' && role != 'adoption_provider')) {
      throw const AdoptionListingRepositoryException(
        'Only owners and adoption providers can manage adoption listings.',
      );
    }
    return role;
  }

  @override
  Future<AdoptionListing> createListing(AdoptionListing listing) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AdoptionListingRepositoryException(
        'You must be signed in to create an adoption listing.',
      );
    }

    if (listing.status != 'draft' && listing.status != 'available') {
      throw const AdoptionListingRepositoryException(
        'An adoption listing must be a draft or available.',
      );
    }

    final role = await _roleFor(user.uid);
    final document = _listingsCollection.doc();
    final persistedListing = AdoptionListing(
      listingId: document.id,
      providerId: role == 'adoption_provider' ? user.uid : '',
      listingOwnerType: role,
      listingOwnerId: user.uid,
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

    final map = AdoptionListingModel.fromEntity(persistedListing).toMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await document.set(map);
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

    if (listing.status != 'draft' && listing.status != 'available') {
      throw const AdoptionListingRepositoryException(
        'An adoption listing must be a draft or available.',
      );
    }

    final reference = _listingsCollection.doc(listing.listingId);
    final document = await reference.get();
    final existing = document.data();
    if (!document.exists || existing == null) {
      throw const AdoptionListingRepositoryException(
        'Adoption listing was not found.',
      );
    }

    final role = await _roleFor(user.uid);
    final legacyProviderId = existing['providerId'] as String? ?? '';
    final ownerType = existing['listingOwnerType'] as String? ?? 'adoption_provider';
    final ownerId = existing['listingOwnerId'] as String? ?? legacyProviderId;
    final canManage = ownerId == user.uid &&
        ((ownerType == 'owner' && role == 'owner') ||
            (ownerType == 'adoption_provider' &&
                role == 'adoption_provider'));

    if (!canManage) {
      throw const AdoptionListingRepositoryException(
        'You are not authorized to update this adoption listing.',
      );
    }

    final persistedListing = AdoptionListing(
      listingId: listing.listingId,
      providerId: ownerType == 'adoption_provider' ? user.uid : '',
      listingOwnerType: ownerType,
      listingOwnerId: ownerId,
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

    final map = AdoptionListingModel.fromEntity(persistedListing).toMap()
      ..['createdAt'] = existing['createdAt']
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await reference.update(map);
  }

  @override
  Stream<List<AdoptionListing>> watchAvailableListings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error(
        const AdoptionListingRepositoryException(
          'You must be signed in to view adoption listings.',
        ),
      );
    }

    return _listingsCollection
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapListings);
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

    return Stream.fromFuture(_roleFor(user.uid)).asyncExpand((role) {
      final query = role == 'owner'
          ? _listingsCollection.where('listingOwnerId', isEqualTo: user.uid)
          : _listingsCollection.where('providerId', isEqualTo: user.uid);
      return query
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(_mapListings);
    });
  }

  @override
  Stream<AdoptionListing?> watchListing({required String listingId}) {
    if (_auth.currentUser == null) {
      return Stream.error(
        const AdoptionListingRepositoryException(
          'You must be signed in to view adoption listings.',
        ),
      );
    }

    return _listingsCollection.doc(listingId).snapshots().map((document) {
      if (!document.exists) return null;
      return AdoptionListingModel.fromFirestore(document);
    });
  }

  List<AdoptionListing> _mapListings(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs.map(AdoptionListingModel.fromFirestore).toList();
}

class AdoptionListingRepositoryException implements Exception {
  const AdoptionListingRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
