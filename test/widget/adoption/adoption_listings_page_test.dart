import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/adoption/data/models/adoption_listing_model.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_listing_repository.dart';
import 'package:petcare/features/adoption/presentation/pages/adoption_listings_page.dart';

class _FakeAdoptionListingRepository implements AdoptionListingRepository {
  _FakeAdoptionListingRepository({this._listings = const []});

  final List<AdoptionListing> _listings;

  @override
  Stream<List<AdoptionListing>> watchAvailableListings() {
    return Stream.value(_listings);
  }

  @override
  Stream<AdoptionListing?> watchListing({required String listingId}) {
    return Stream.value(
      _listings.where((listing) => listing.listingId == listingId).firstOrNull,
    );
  }
}

void main() {
  testWidgets('shows empty state when there are no adoption listings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdoptionListingsPage(
          adoptionListingRepository: _FakeAdoptionListingRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No adoption listings found'), findsOneWidget);

    expect(
      find.text('Try changing your search or check back later for new pets.'),
      findsOneWidget,
    );
  });

  testWidgets('shows adoption listings when repository returns data', (
    tester,
  ) async {
    final listing = AdoptionListingModel(
      listingId: 'listing-1',
      providerId: 'provider-1',
      petName: 'Buddy',
      species: 'Dog',
      breed: 'Labrador',
      ageDescription: '2 years',
      gender: 'Male',
      description: 'Friendly dog looking for a home.',
      location: 'Colombo',
      status: 'available',
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdoptionListingsPage(
          adoptionListingRepository: _FakeAdoptionListingRepository(
            listings: [listing],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Dog • Labrador • 2 years'), findsOneWidget);
    expect(find.text('Colombo'), findsOneWidget);
  });

  testWidgets('filters adoption listings using the search field', (
    tester,
  ) async {
    final listings = [
      AdoptionListingModel(
        listingId: 'listing-1',
        providerId: 'provider-1',
        petName: 'Buddy',
        species: 'Dog',
        breed: 'Labrador',
        ageDescription: '2 years',
        gender: 'Male',
        description: 'Friendly dog looking for a home.',
        location: 'Colombo',
        status: 'available',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      ),
      AdoptionListingModel(
        listingId: 'listing-2',
        providerId: 'provider-2',
        petName: 'Milo',
        species: 'Cat',
        breed: 'Persian',
        ageDescription: '1 year',
        gender: 'Male',
        description: 'Calm cat looking for a home.',
        location: 'Kandy',
        status: 'available',
        createdAt: DateTime(2026, 9, 2),
        updatedAt: DateTime(2026, 9, 2),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AdoptionListingsPage(
          adoptionListingRepository: _FakeAdoptionListingRepository(
            listings: listings,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Milo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Kandy');

    await tester.pump();

    expect(find.text('Milo'), findsOneWidget);
    expect(find.text('Buddy'), findsNothing);
  });
}
