import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_request.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_listing_repository.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_request_decision_repository.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_request_repository.dart';
import 'package:petcare/features/adoption/presentation/pages/adoption_request_details_page.dart';

void main() {
  group('AdoptionRequestDetailsPage', () {
    testWidgets(
      'authorized provider sees decision controls and confirms acceptance',
      (tester) async {
        final requestRepository = _FakeRequestRepository(
          request: _request(status: 'pending'),
        );
        final listingRepository = _FakeListingRepository(listing: _listing());

        await tester.pumpWidget(
          MaterialApp(
            home: AdoptionRequestDetailsPage(
              requestId: 'request-1',
              currentUserId: 'provider-1',
              adoptionRequestRepository: requestRepository,
              decisionRepository: requestRepository,
              adoptionListingRepository: listingRepository,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Adoption Request Details'), findsOneWidget);
        expect(find.text('Could you consider my application?'), findsOneWidget);
        expect(find.text('Buddy'), findsOneWidget);
        expect(find.text('Accept Request'), findsOneWidget);
        expect(find.text('Reject Request'), findsOneWidget);

        await tester.ensureVisible(find.text('Accept Request'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Accept Request'));
        await tester.pumpAndSettle();

        expect(find.text('Accept this adoption request?'), findsOneWidget);

        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        expect(requestRepository.lastDecision, 'accepted');
        expect(find.text('Adoption request accepted.'), findsOneWidget);
      },
    );

    testWidgets(
      'requesting owner can view details but cannot decide the request',
      (tester) async {
        final request = _request(status: 'pending');

        await tester.pumpWidget(
          MaterialApp(
            home: AdoptionRequestDetailsPage(
              requestId: 'request-1',
              currentUserId: 'requester-1',
              adoptionRequestRepository: _FakeRequestRepository(
                request: request,
              ),
              decisionRepository: _FakeRequestRepository(request: request),
              adoptionListingRepository: _FakeListingRepository(
                listing: _listing(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // The requester can still see their own request details.
        expect(find.text('Adoption Request Details'), findsOneWidget);
        expect(find.text('Could you consider my application?'), findsOneWidget);
        expect(find.text('Buddy'), findsOneWidget);

        // The requester must not receive provider decision controls.
        expect(find.text('Accept Request'), findsNothing);
        expect(find.text('Reject Request'), findsNothing);

        expect(
          find.text(
            'Only the adoption provider managing this listing can '
            'accept or reject this request.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('hides decision controls when request is not pending', (
      tester,
    ) async {
      final request = _request(status: 'rejected');

      await tester.pumpWidget(
        MaterialApp(
          home: AdoptionRequestDetailsPage(
            requestId: 'request-1',
            currentUserId: 'provider-1',
            adoptionRequestRepository: _FakeRequestRepository(request: request),
            decisionRepository: _FakeRequestRepository(request: request),
            adoptionListingRepository: _FakeListingRepository(
              listing: _listing(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reject Request'), findsNothing);
      expect(find.text('Accept Request'), findsNothing);

      expect(
        find.text('This request is no longer pending and cannot be changed.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'hides decision controls when canonical recipient metadata is missing',
      (tester) async {
        final request = _request(status: 'pending', recipientId: null);

        await tester.pumpWidget(
          MaterialApp(
            home: AdoptionRequestDetailsPage(
              requestId: 'request-1',
              currentUserId: 'provider-1',
              adoptionRequestRepository: _FakeRequestRepository(
                request: request,
              ),
              decisionRepository: _FakeRequestRepository(request: request),
              adoptionListingRepository: _FakeListingRepository(
                listing: _listing(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Buddy'), findsOneWidget);

        // providerId is present in the legacy field, but it must not
        // substitute for canonical recipientId authorization.
        expect(find.text('Accept Request'), findsNothing);
        expect(find.text('Reject Request'), findsNothing);
      },
    );
  });
}

/// Creates an adoption request fixture.
///
/// Canonical recipient metadata is populated by default.
/// Tests can explicitly remove recipientId to simulate legacy requests.
AdoptionRequest _request({
  required String status,
  String? recipientId = 'provider-1',
  String recipientType = 'adoption_provider',
}) {
  final now = DateTime(2026, 10, 18, 10);

  return AdoptionRequest(
    requestId: 'request-1',
    listingId: 'listing-1',
    requesterId: 'requester-1',
    providerId: 'provider-1',
    recipientId: recipientId,
    recipientType: recipientType,
    message: 'Could you consider my application?',
    status: status,
    submittedAt: now,
    updatedAt: now,
  );
}

AdoptionListing _listing() {
  final now = DateTime(2026, 10, 18, 9);

  return AdoptionListing(
    listingId: 'listing-1',
    providerId: 'provider-1',
    petName: 'Buddy',
    species: 'Dog',
    breed: 'Labrador',
    ageDescription: '2 years',
    gender: 'Male',
    description: 'Friendly and ready for a loving home.',
    location: 'Colombo',
    status: 'available',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeRequestRepository
    implements AdoptionRequestRepository, AdoptionRequestDecisionRepository {
  _FakeRequestRepository({required this.request});

  final AdoptionRequest request;

  String? lastDecision;

  @override
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? recipientId,
    String recipientType = 'adoption_provider',
    String? message,
  }) async {}

  @override
  Stream<List<AdoptionRequest>> watchMyRequests() {
    return Stream.value([request]);
  }

  @override
  Stream<AdoptionRequest?> watchRequest({required String requestId}) {
    return Stream.value(requestId == request.requestId ? request : null);
  }

  @override
  Stream<List<AdoptionRequest>> watchReceivedRequests() {
    return Stream.value([request]);
  }

  @override
  Future<void> acceptRequest({
    required String requestId,
    String? providerNote,
  }) async {
    lastDecision = 'accepted';
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    String? providerNote,
  }) async {
    lastDecision = 'rejected';
  }
}

class _FakeListingRepository implements AdoptionListingRepository {
  _FakeListingRepository({required this.listing});

  final AdoptionListing listing;

  @override
  Future<AdoptionListing> createListing(AdoptionListing value) async {
    return listing;
  }

  @override
  Stream<List<AdoptionListing>> watchAvailableListings() {
    return Stream.value([listing]);
  }

  @override
  Stream<AdoptionListing?> watchListing({required String listingId}) {
    return Stream.value(listingId == listing.listingId ? listing : null);
  }

  @override
  Stream<List<AdoptionListing>> watchMyListings() {
    return Stream.value([listing]);
  }

  @override
  Future<void> updateListing(AdoptionListing value) async {}
}
