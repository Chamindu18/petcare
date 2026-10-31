import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/data/repositories/firebase_adoption_request_repository.dart';

MockFirebaseAuth _authAs(String uid) {
  return MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid));
}

Future<void> _seedProviderListing(
  FakeFirebaseFirestore firestore, {
  String listingId = 'listing-1',
  String providerId = 'provider-1',
}) async {
  await firestore.collection('adoption_listings').doc(listingId).set({
    'listingOwnerType': 'adoption_provider',
    'listingOwnerId': providerId,
    'providerId': providerId,
    'petName': 'Buddy',
    'species': 'Dog',
    'gender': 'Male',
    'description': 'Friendly dog looking for a home.',
    'location': 'Colombo',
    'status': 'available',
    'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
    'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
  });
}

void main() {
  group('FirebaseAdoptionRequestRepository provider-only access', () {
    test('allows an owner to request a provider listing', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = _authAs('owner-1');

      await firestore.collection('users').doc('owner-1').set({'role': 'owner'});
      await firestore.collection('users').doc('provider-1').set({
        'role': 'adoption_provider',
      });
      await _seedProviderListing(firestore);

      final repository = FirebaseAdoptionRequestRepository(
        auth: auth,
        firestore: firestore,
      );

      await repository.createRequest(
        listingId: 'listing-1',
        providerId: 'provider-1',
        recipientId: 'provider-1',
        recipientType: 'adoption_provider',
        message: 'I would like to adopt Buddy.',
      );

      final requests = await firestore.collection('adoption_requests').get();

      expect(requests.docs, hasLength(1));
      expect(requests.docs.first.data()['requesterId'], 'owner-1');
      expect(requests.docs.first.data()['recipientId'], 'provider-1');
      expect(requests.docs.first.data()['recipientType'], 'adoption_provider');
      expect(requests.docs.first.data()['status'], 'pending');
    });

    test('rejects requests to an owner-owned listing', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = _authAs('owner-1');

      await firestore.collection('users').doc('owner-1').set({'role': 'owner'});
      await firestore.collection('adoption_listings').doc('listing-1').set({
        'listingOwnerType': 'owner',
        'listingOwnerId': 'owner-2',
        'petName': 'Buddy',
        'status': 'available',
      });

      final repository = FirebaseAdoptionRequestRepository(
        auth: auth,
        firestore: firestore,
      );

      await expectLater(
        repository.createRequest(
          listingId: 'listing-1',
          providerId: 'owner-2',
          recipientId: 'owner-2',
          recipientType: 'owner',
        ),
        throwsA(isA<AdoptionRequestRepositoryException>()),
      );

      final requests = await firestore.collection('adoption_requests').get();
      expect(requests.docs, isEmpty);
    });

    test('prevents owners from viewing received requests', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = _authAs('owner-1');

      await firestore.collection('users').doc('owner-1').set({'role': 'owner'});

      final repository = FirebaseAdoptionRequestRepository(
        auth: auth,
        firestore: firestore,
      );

      await expectLater(
        repository.watchReceivedRequests(),
        emitsError(isA<AdoptionRequestRepositoryException>()),
      );
    });

    test('prevents owners from accepting adoption requests', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = _authAs('owner-1');

      await firestore.collection('users').doc('owner-1').set({'role': 'owner'});

      final repository = FirebaseAdoptionRequestRepository(
        auth: auth,
        firestore: firestore,
      );

      await expectLater(
        repository.acceptRequest(requestId: 'request-1'),
        throwsA(isA<AdoptionRequestRepositoryException>()),
      );
    });

    test('provider acceptance atomically reserves its listing', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = _authAs('provider-1');

      await firestore.collection('users').doc('provider-1').set({
        'role': 'adoption_provider',
      });
      await _seedProviderListing(firestore);

      await firestore.collection('adoption_requests').doc('request-1').set({
        'listingId': 'listing-1',
        'requesterId': 'owner-1',
        'recipientId': 'provider-1',
        'recipientType': 'adoption_provider',
        'providerId': 'provider-1',
        'status': 'pending',
        'submittedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      });

      final repository = FirebaseAdoptionRequestRepository(
        auth: auth,
        firestore: firestore,
      );

      await repository.acceptRequest(requestId: 'request-1');

      final request = await firestore
          .collection('adoption_requests')
          .doc('request-1')
          .get();
      final listing = await firestore
          .collection('adoption_listings')
          .doc('listing-1')
          .get();

      expect(request.data()?['status'], 'accepted');
      expect(listing.data()?['status'], 'reserved');
      expect(listing.data()?['acceptedRequestId'], 'request-1');
    });
  });
}
