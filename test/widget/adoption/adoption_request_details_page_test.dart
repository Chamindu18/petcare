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
    testWidgets('shows request and listing details and confirms acceptance', (
      tester,
    ) async {
      final requestRepository = _FakeRequestRepository(
        request: _request(status: 'pending'),
      );
      final listingRepository = _FakeListingRepository(listing: _listing());

      await tester.pumpWidget(
        MaterialApp(
          home: AdoptionRequestDetailsPage(
            requestId: 'request-1',
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
    });

    testWidgets('hides decision controls when request is not pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdoptionRequestDetailsPage(
            requestId: 'request-1',
            adoptionRequestRepository: _FakeRequestRepository(
              request: _request(status: 'rejected'),
            ),
            decisionRepository: _FakeRequestRepository(
              request: _request(status: 'rejected'),
            ),
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
  });
}

AdoptionRequest _request({required String status}) {
  final now = DateTime(2026, 10, 18, 10);
  return AdoptionRequest(
    requestId: 'request-1',
    listingId: 'listing-1',
    requesterId: 'requester-1',
    providerId: 'provider-1',
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
  _FakeRequestRepository({required this._request});

  final AdoptionRequest _request;
  String? lastDecision;

  @override
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? message,
  }) async {}

  @override
  Stream<List<AdoptionRequest>> watchMyRequests() => Stream.value([_request]);

  @override
  Stream<AdoptionRequest?> watchRequest({required String requestId}) =>
      Stream.value(requestId == _request.requestId ? _request : null);

  @override
  Stream<List<AdoptionRequest>> watchReceivedRequests() =>
      Stream.value([_request]);

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
  _FakeListingRepository({required this._listing});

  final AdoptionListing _listing;

  @override
  Future<AdoptionListing> createListing(AdoptionListing listing) async =>
      _listing;

  @override
  Stream<List<AdoptionListing>> watchAvailableListings() =>
      Stream.value([_listing]);

  @override
  Stream<AdoptionListing?> watchListing({required String listingId}) =>
      Stream.value(listingId == _listing.listingId ? _listing : null);

  @override
  Stream<List<AdoptionListing>> watchMyListings() => Stream.value([_listing]);

  @override
  Future<void> updateListing(AdoptionListing listing) async {}
}
