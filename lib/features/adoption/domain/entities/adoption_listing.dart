class AdoptionListing {
  const AdoptionListing({
    required this.listingId,
    required this.providerId,
    required this.petName,
    required this.species,
    this.breed,
    this.ageDescription,
    required this.gender,
    required this.description,
    required this.location,
    this.imageAsset,
    required this.status,
    this.contactNote,
    required this.createdAt,
    required this.updatedAt,
    this.listingOwnerType = 'adoption_provider',
    this.listingOwnerId,
  });

  final String listingId;

  /// Legacy provider field. Empty for new owner rehoming listings.
  final String providerId;
  final String listingOwnerType;
  final String? listingOwnerId;

  /// Canonical owner with a fallback for existing provider listings.
  String get effectiveListingOwnerId => listingOwnerId ?? providerId;

  final String petName;
  final String species;
  final String? breed;
  final String? ageDescription;
  final String gender;
  final String description;
  final String location;
  final String? imageAsset;
  final String status;
  final String? contactNote;
  final DateTime createdAt;
  final DateTime updatedAt;
}
