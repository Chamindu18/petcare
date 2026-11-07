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
    this.acceptedRequestId,
  });

  final String listingId;

  /// Legacy provider field. Empty for new owner rehoming listings.
  final String providerId;

  final String listingOwnerType;
  final String? listingOwnerId;

  /// ID of the request that reserved this listing, if accepted.
  final String? acceptedRequestId;

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

  AdoptionListing copyWith({
    String? listingId,
    String? providerId,
    String? petName,
    String? species,
    String? breed,
    String? ageDescription,
    String? gender,
    String? description,
    String? location,
    String? imageAsset,
    String? status,
    String? contactNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? listingOwnerType,
    String? listingOwnerId,
    String? acceptedRequestId,
  }) {
    return AdoptionListing(
      listingId: listingId ?? this.listingId,
      providerId: providerId ?? this.providerId,
      petName: petName ?? this.petName,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      ageDescription: ageDescription ?? this.ageDescription,
      gender: gender ?? this.gender,
      description: description ?? this.description,
      location: location ?? this.location,
      imageAsset: imageAsset ?? this.imageAsset,
      status: status ?? this.status,
      contactNote: contactNote ?? this.contactNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      listingOwnerType: listingOwnerType ?? this.listingOwnerType,
      listingOwnerId: listingOwnerId ?? this.listingOwnerId,
      acceptedRequestId: acceptedRequestId ?? this.acceptedRequestId,
    );
  }
}