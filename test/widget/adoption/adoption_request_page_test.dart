import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/data/models/adoption_listing_model.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_request_repository.dart';
import 'package:petcare/features/adoption/presentation/pages/adoption_request_page.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_request.dart';

class _FakeAdoptionRequestRepository implements AdoptionRequestRepository {
  bool createRequestCalled = false;
  String? submittedListingId;
  String? submittedProviderId;
  String? submittedMessage;

  @override
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? message,
  }) async {
    createRequestCalled = true;
    submittedListingId = listingId;
    submittedProviderId = providerId;
    submittedMessage = message;
  }

  @override
  Stream<AdoptionRequest?> watchRequest({required String requestId}) {
    return const Stream.empty();
  }
}

AdoptionListing _createListing() {
  return AdoptionListingModel(
    listingId: 'listing-1',
    providerId: 'provider-1',
    petName: 'Buddy',
    species: 'Dog',
    breed: 'Labrador',
    ageDescription: '2 years',
    gender: 'Male',
    description: 'Friendly dog looking for a loving home.',
    location: 'Colombo',
    status: 'available',
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );
}

Widget _buildPage({required AdoptionRequestRepository repository}) {
  return MaterialApp(
    home: AdoptionRequestPage(
      listing: _createListing(),
      adoptionRequestRepository: repository,
    ),
  );
}

void main() {
  testWidgets(
    'shows validation message when adoption request message is empty',
    (tester) async {
      final repository = _FakeAdoptionRequestRepository();

      await tester.pumpWidget(_buildPage(repository: repository));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit Adoption Request'));
      await tester.pump();

      expect(find.text('Please enter a message.'), findsOneWidget);
      expect(repository.createRequestCalled, isFalse);
    },
  );

  testWidgets(
    'submits adoption request with listing and provider identifiers',
    (tester) async {
      final repository = _FakeAdoptionRequestRepository();

      await tester.pumpWidget(_buildPage(repository: repository));

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'I would love to adopt Buddy.',
      );

      await tester.tap(find.text('Submit Adoption Request'));
      await tester.pumpAndSettle();

      expect(repository.createRequestCalled, isTrue);
      expect(repository.submittedListingId, 'listing-1');
      expect(repository.submittedProviderId, 'provider-1');
      expect(repository.submittedMessage, 'I would love to adopt Buddy.');
    },
  );
}
