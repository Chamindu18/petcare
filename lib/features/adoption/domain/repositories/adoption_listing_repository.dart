import '../entities/adoption_listing.dart';

abstract interface class AdoptionListingRepository {
  Stream<List<AdoptionListing>> watchAvailableListings();

  Stream<AdoptionListing?> watchListing({required String listingId});

  Stream<List<AdoptionListing>> watchMyListings();
}
