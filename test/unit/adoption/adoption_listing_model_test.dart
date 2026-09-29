import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/adoption/data/models/adoption_listing_model.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';

void main() {
  test('converts adoption listing entity to Firestore map', () {
    final listing = AdoptionListing(
      listingId: 'listing-1',
      providerId: 'provider-1',
      petName: 'Buddy',
      species: 'Dog',
      breed: 'Golden Retriever',
      ageDescription: '2 years',
      gender: 'Male',
      description: 'Friendly dog looking for a home.',
      location: 'Colombo',
      imageAsset: 'https://example.com/buddy.jpg',
      status: 'draft',
      contactNote: 'Contact through PetCare+.',
      createdAt: DateTime(2026, 9, 1, 10),
      updatedAt: DateTime(2026, 9, 1, 11),
    );

    final model = AdoptionListingModel.fromEntity(listing);
    final map = model.toMap();

    expect(map['providerId'], 'provider-1');
    expect(map['petName'], 'Buddy');
    expect(map['species'], 'Dog');
    expect(map['breed'], 'Golden Retriever');
    expect(map['ageDescription'], '2 years');
    expect(map['gender'], 'Male');
    expect(map['description'], 'Friendly dog looking for a home.');
    expect(map['location'], 'Colombo');
    expect(map['imageAsset'], 'https://example.com/buddy.jpg');
    expect(map['status'], 'draft');
    expect(map['contactNote'], 'Contact through PetCare+.');
    expect(map['createdAt'], Timestamp.fromDate(DateTime(2026, 9, 1, 10)));
    expect(map['updatedAt'], Timestamp.fromDate(DateTime(2026, 9, 1, 11)));
  });

  test('omits optional empty fields from Firestore map', () {
    final listing = AdoptionListing(
      listingId: 'listing-2',
      providerId: 'provider-2',
      petName: 'Milo',
      species: 'Cat',
      gender: 'Female',
      description: 'Calm cat looking for a home.',
      location: 'Kandy',
      status: 'draft',
      createdAt: DateTime(2026, 9, 2),
      updatedAt: DateTime(2026, 9, 2),
    );

    final model = AdoptionListingModel.fromEntity(listing);
    final map = model.toMap();

    expect(map.containsKey('breed'), isFalse);
    expect(map.containsKey('ageDescription'), isFalse);
    expect(map.containsKey('imageAsset'), isFalse);
    expect(map.containsKey('contactNote'), isFalse);
  });
}
