import '../entities/adoption_listing.dart';

abstract interface class AdoptionListingRepository {
  Future<AdoptionListing> createListing(AdoptionListing listing);

  Stream<List<AdoptionListing>> watchAvailableListings();

  Stream<AdoptionListing?> watchListing({required String listingId});

  Stream<List<AdoptionListing>> watchMyListings();

  Future<void> updateListing(AdoptionListing listing);
}
