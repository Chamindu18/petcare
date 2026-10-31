import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/data/models/adoption_request_model.dart';

void main() {
  group('AdoptionRequestModel', () {
    test('preserves canonical recipient metadata', () async {
      final firestore = FakeFirebaseFirestore();

      await firestore.collection('adoption_requests').doc('request-1').set({
        'listingId': 'listing-1',
        'requesterId': 'owner-1',
        'providerId': 'provider-1',
        'recipientId': 'provider-1',
        'recipientType': 'adoption_provider',
        'status': 'pending',
        'submittedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      });

      final document = await firestore
          .collection('adoption_requests')
          .doc('request-1')
          .get();

      final request = AdoptionRequestModel.fromFirestore(document);

      expect(request.recipientId, 'provider-1');
      expect(request.recipientType, 'adoption_provider');
      expect(request.providerId, 'provider-1');
    });

    test(
      'does not infer canonical recipientId from legacy providerId',
      () async {
        final firestore = FakeFirebaseFirestore();

        await firestore
            .collection('adoption_requests')
            .doc('legacy-request')
            .set({
              'listingId': 'listing-1',
              'requesterId': 'owner-1',
              'providerId': 'provider-1',
              'status': 'pending',
              'submittedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
              'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
            });

        final document = await firestore
            .collection('adoption_requests')
            .doc('legacy-request')
            .get();

        final request = AdoptionRequestModel.fromFirestore(document);

        // Legacy providerId remains available for compatibility.
        expect(request.providerId, 'provider-1');

        // But it must not become canonical authorization metadata.
        expect(request.recipientId, isNull);

        // The model's legacy convenience getter remains backward compatible.
        expect(request.effectiveRecipientId, 'provider-1');
      },
    );
  });
}
