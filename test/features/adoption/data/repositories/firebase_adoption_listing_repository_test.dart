import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/data/repositories/firebase_adoption_listing_repository.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';

AdoptionListing _listing() {
  return AdoptionListing(
    listingId: 'listing-1',
    providerId: 'provider-1',
    petName: 'Buddy',
    species: 'Dog',
    gender: 'Male',
    description: 'Friendly dog looking for a home.',
    location: 'Colombo',
    status: 'available',
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
  );
}

void main() {
  group('FirebaseAdoptionListingRepository provider-only access', () {
    test(
      'allows a provider to create a listing with correct ownership',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'provider-1'),
        );

        await firestore.collection('users').doc('provider-1').set({
          'role': 'adoption_provider',
        });

        final repository = FirebaseAdoptionListingRepository(
          auth: auth,
          firestore: firestore,
        );

        final createdListing = await repository.createListing(_listing());
        final savedListing = await firestore
            .collection('adoption_listings')
            .doc(createdListing.listingId)
            .get();

        expect(savedListing.exists, isTrue);
        expect(savedListing.data()?['providerId'], 'provider-1');
        expect(savedListing.data()?['listingOwnerType'], 'adoption_provider');
        expect(savedListing.data()?['listingOwnerId'], 'provider-1');
      },
    );
    test('rejects an owner attempting to create a listing', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'owner-1'),
      );

      await firestore.collection('users').doc('owner-1').set({'role': 'owner'});

      final repository = FirebaseAdoptionListingRepository(
        auth: auth,
        firestore: firestore,
      );

      await expectLater(
        repository.createListing(_listing()),
        throwsA(isA<AdoptionListingRepositoryException>()),
      );

      final listings = await firestore.collection('adoption_listings').get();
      expect(listings.docs, isEmpty);
    });

    test('rejects an owner attempting to update a listing', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'owner-1'),
      );

      await firestore.collection('users').doc('owner-1').set({'role': 'owner'});

      await firestore.collection('adoption_listings').doc('listing-1').set({
        'listingOwnerType': 'owner',
        'listingOwnerId': 'owner-1',
        'petName': 'Buddy',
        'species': 'Dog',
        'gender': 'Male',
        'description': 'Friendly dog looking for a home.',
        'location': 'Colombo',
        'status': 'available',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      });

      final repository = FirebaseAdoptionListingRepository(
        auth: auth,
        firestore: firestore,
      );

      await expectLater(
        repository.updateListing(_listing()),
        throwsA(isA<AdoptionListingRepositoryException>()),
      );

      final savedListing = await firestore
          .collection('adoption_listings')
          .doc('listing-1')
          .get();

      expect(
        savedListing.data()?['description'],
        'Friendly dog looking for a home.',
      );
    });
  });
}
