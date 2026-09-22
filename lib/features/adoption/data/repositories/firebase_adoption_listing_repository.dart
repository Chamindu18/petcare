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
