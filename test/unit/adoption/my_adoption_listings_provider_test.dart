import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_listing_repository.dart';
import 'package:petcare/features/adoption/presentation/providers/my_adoption_listings_provider.dart';

class _FakeAdoptionListingRepository implements AdoptionListingRepository {
  _FakeAdoptionListingRepository({this.listings = const [], this.error});

  final List<AdoptionListing> listings;
  final Object? error;

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

AdoptionListing _createListing() {
  return AdoptionListing(
    listingId: 'listing-1',
    providerId: 'provider-1',
    petName: 'Buddy',
    species: 'Dog',
    gender: 'Male',
    description: 'Friendly dog looking for a home.',
    location: 'Colombo',
    status: 'available',
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );
}

void main() {
  test('loads provider listings successfully', () async {
    final provider = MyAdoptionListingsProvider(
      repository: _FakeAdoptionListingRepository(listings: [_createListing()]),
    );

    provider.startListening();

    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.listings, hasLength(1));
    expect(provider.listings.single.petName, 'Buddy');
    expect(provider.hasNoListings, isFalse);

    provider.dispose();
  });

  test('shows empty state when provider has no listings', () async {
    final provider = MyAdoptionListingsProvider(
      repository: _FakeAdoptionListingRepository(),
    );

    provider.startListening();

    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.listings, isEmpty);
    expect(provider.hasNoListings, isTrue);

    provider.dispose();
  });

  test('shows error when provider listings fail to load', () async {
    final provider = MyAdoptionListingsProvider(
      repository: _FakeAdoptionListingRepository(
        error: StateError('network error'),
      ),
    );

    provider.startListening();

    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(
      provider.errorMessage,
      'Unable to load your adoption listings. Please try again.',
    );
    expect(provider.hasNoListings, isFalse);

    provider.dispose();
  });
}
