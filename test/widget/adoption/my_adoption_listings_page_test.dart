import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_listing_repository.dart';
import 'package:petcare/features/adoption/presentation/pages/my_adoption_listings_page.dart';

class _FakeAdoptionListingRepository implements AdoptionListingRepository {
  _FakeAdoptionListingRepository({this.listings = const [], this.error});

  final List<AdoptionListing> listings;
  final Object? error;

  @override
  Future<AdoptionListing> createListing(AdoptionListing listing) {
    return Future.value(listing);
  }

  @override
  Future<void> updateListing(AdoptionListing listing) async {}

  @override
  Stream<List<AdoptionListing>> watchAvailableListings() {
    return Stream.value(listings);
  }

  @override
  Stream<AdoptionListing?> watchListing({required String listingId}) {
    return Stream.value(
      listings.where((listing) => listing.listingId == listingId).firstOrNull,
    );
  }

  @override
  Stream<List<AdoptionListing>> watchMyListings() {
    if (error != null) {
      return Stream<List<AdoptionListing>>.error(error!);
    }

    return Stream.value(listings);
  }
}

AdoptionListing _createListing({String status = 'available'}) {
  return AdoptionListing(
    listingId: 'listing-1',
    providerId: 'provider-1',
    petName: 'Buddy',
    species: 'Dog',
    breed: 'Labrador',
    ageDescription: '2 years',
    gender: 'Male',
    description: 'Friendly and looking for a loving home.',
    location: 'Colombo',
    status: status,
    createdAt: DateTime(2026, 9, 20),
    updatedAt: DateTime(2026, 9, 20),
  );
}

Widget _buildPage({required AdoptionListingRepository repository}) {
  return MaterialApp(
    home: MyAdoptionListingsPage(adoptionListingRepository: repository),
  );
}

void main() {
  testWidgets('shows adoption listings and their status', (tester) async {
    final repository = _FakeAdoptionListingRepository(
      listings: [
        _createListing(status: 'available'),
        _createListing(status: 'adopted'),
      ],
    );

    await tester.pumpWidget(_buildPage(repository: repository));

    await tester.pumpAndSettle();

    expect(find.text('My Adoption Listings'), findsOneWidget);
    expect(find.text('Buddy'), findsNWidgets(2));
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Adopted'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no adoption listings', (
    tester,
  ) async {
    final repository = _FakeAdoptionListingRepository();

    await tester.pumpWidget(_buildPage(repository: repository));

    await tester.pumpAndSettle();

    expect(find.text('No adoption listings yet'), findsOneWidget);
    expect(
      find.text(
        'Your adoption listings will appear here after you create one.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows error state when listings cannot be loaded', (
    tester,
  ) async {
    final repository = _FakeAdoptionListingRepository(
      error: StateError('Network error'),
    );

    await tester.pumpWidget(_buildPage(repository: repository));

    await tester.pumpAndSettle();

    expect(find.text('Unable to load your adoption listings'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
