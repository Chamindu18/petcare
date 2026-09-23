import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/adoption/data/models/adoption_listing_model.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_listing_repository.dart';
import 'package:petcare/features/adoption/presentation/pages/adoption_pet_details_page.dart';

class _FakeAdoptionListingRepository implements AdoptionListingRepository {
  _FakeAdoptionListingRepository({this._listing, this._error});

  final AdoptionListing? _listing;
  final Object? _error;

  @override
  Stream<List<AdoptionListing>> watchAvailableListings() {
    return Stream.value(_listing == null ? const [] : [_listing]);
  }

  @override
  Stream<AdoptionListing?> watchListing({required String listingId}) {
    if (_error != null) {
      return Stream<AdoptionListing?>.error(_error);
    }

    return Stream.value(_listing);
  }
}

AdoptionListing _createListing({String status = 'available'}) {
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
    status: status,
    contactNote: 'Please contact the provider for adoption arrangements.',
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );
}

Widget _buildPage({required AdoptionListingRepository repository}) {
  return MaterialApp(
    home: AdoptionPetDetailsPage(
      listingId: 'listing-1',
      adoptionListingRepository: repository,
    ),
  );
}

void main() {
  testWidgets('shows pet details when listing is available', (tester) async {
    await tester.pumpWidget(
      _buildPage(
        repository: _FakeAdoptionListingRepository(listing: _createListing()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Dog • Labrador • 2 years'), findsOneWidget);
    expect(find.text('Colombo'), findsOneWidget);
    expect(find.text('Request Adoption'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
  });

  testWidgets('shows unavailable state when listing no longer exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildPage(repository: _FakeAdoptionListingRepository()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Listing unavailable'), findsOneWidget);
    expect(
      find.text('This adoption listing is no longer available.'),
      findsOneWidget,
    );
    expect(find.text('Back to listings'), findsOneWidget);
  });

  testWidgets('shows listing status when adoption is pending', (tester) async {
    await tester.pumpWidget(
      _buildPage(
        repository: _FakeAdoptionListingRepository(
          listing: _createListing(status: 'pending'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Request Adoption'), findsNothing);
  });

  testWidgets('shows error state when listing cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildPage(
        repository: _FakeAdoptionListingRepository(
          error: StateError('Network error'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unable to load pet details'), findsOneWidget);
    expect(
      find.text('Please check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });
}
