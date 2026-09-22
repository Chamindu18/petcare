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
  });

  final String listingId;
  final String providerId;
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
