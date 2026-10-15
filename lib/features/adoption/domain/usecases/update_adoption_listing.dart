import '../entities/adoption_listing.dart';
import '../repositories/adoption_listing_repository.dart';

class UpdateAdoptionListing {
  const UpdateAdoptionListing(this._repository);

  final AdoptionListingRepository _repository;

  Future<void> call(AdoptionListing listing) {
    return _repository.updateListing(listing);
  }
}
