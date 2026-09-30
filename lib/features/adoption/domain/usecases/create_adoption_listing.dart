import '../entities/adoption_listing.dart';
import '../repositories/adoption_listing_repository.dart';

class CreateAdoptionListing {
  const CreateAdoptionListing(this._repository);

  final AdoptionListingRepository _repository;

  Future<AdoptionListing> call(AdoptionListing listing) {
    return _repository.createListing(listing);
  }
}
