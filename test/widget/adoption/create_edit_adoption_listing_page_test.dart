import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_listing_repository.dart';
import 'package:petcare/features/adoption/presentation/pages/create_edit_adoption_listing_page.dart';

class _FakeAdoptionListingRepository implements AdoptionListingRepository {
  _FakeAdoptionListingRepository({
    this.createError,
    this.updateError,
  });

  final Object? createError;
  final Object? updateError;

  AdoptionListing? createdListing;
  AdoptionListing? updatedListing;

  @override
  Future<AdoptionListing> createListing(AdoptionListing listing) async {
    if (createError != null) {
      throw createError!;
    }

    createdListing = AdoptionListing(
      listingId: 'listing-1',
      providerId: listing.providerId,
      petName: listing.petName,
      species: listing.species,
      breed: listing.breed,
      ageDescription: listing.ageDescription,
      gender: listing.gender,
      description: listing.description,
      location: listing.location,
      imageAsset: listing.imageAsset,
      status: listing.status,
      contactNote: listing.contactNote,
      createdAt: listing.createdAt,
      updatedAt: listing.updatedAt,
    );

    return createdListing!;
  }

  @override
  Future<void> updateListing(AdoptionListing listing) async {
    if (updateError != null) {
      throw updateError!;
    }

    updatedListing = listing;
  }

  @override
  Stream<List<AdoptionListing>> watchAvailableListings() {
    return const Stream.empty();
  }

  @override
  Stream<AdoptionListing?> watchListing({
    required String listingId,
  }) {
    return Stream.value(null);
  }

  @override
  Stream<List<AdoptionListing>> watchMyListings() {
    return const Stream.empty();
  }
}

AdoptionListing _createListing() {
  return AdoptionListing(
    listingId: 'listing-1',
    providerId: 'provider-1',
    petName: 'Buddy',
    species: 'Dog',
    breed: 'Labrador',
    ageDescription: '2 years',
    gender: 'Male',
    description: 'Friendly dog looking for a loving home.',
    location: 'Colombo',
    imageAsset: 'buddy.jpg',
    status: 'draft',
    contactNote: 'Contact through PetCare+.',
    createdAt: DateTime(2026, 9, 20),
    updatedAt: DateTime(2026, 9, 20),
  );
}

Widget _buildPage({
  required AdoptionListingRepository repository,
  AdoptionListing? listing,
}) {
  return MaterialApp(
    home: CreateEditAdoptionListingPage(
      adoptionListingRepository: repository,
      listing: listing,
    ),
  );
}

/// Selects a value from a DropdownButtonFormField.
///
/// The dropdown may be inside a scrollable form, so we first make it
/// visible, open it using its lower area, then select the requested value.
Future<void> _selectDropdownValue(
  WidgetTester tester,
  Finder dropdown,
  String value,
) async {
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();

  final rect = tester.getRect(dropdown);

  await tester.tapAt(
    Offset(
      rect.center.dx,
      rect.bottom - 8,
    ),
  );

  await tester.pumpAndSettle();

  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders create listing form', (tester) async {
    final repository = _FakeAdoptionListingRepository();

    await tester.pumpWidget(
      _buildPage(repository: repository),
    );

    expect(
      find.text('Create Adoption Listing'),
      findsOneWidget,
    );

    expect(
      find.byType(TextFormField),
      findsNWidgets(7),
    );

    expect(
      find.byType(DropdownButtonFormField<String>),
      findsNWidgets(2),
    );

    expect(
      find.text('Save Draft'),
      findsOneWidget,
    );

    expect(
      find.text('Publish'),
      findsOneWidget,
    );
  });

  testWidgets(
    'validation prevents submission with missing required fields',
    (tester) async {
      final repository = _FakeAdoptionListingRepository();

      await tester.pumpWidget(
        _buildPage(repository: repository),
      );

      final publishButton = find.widgetWithText(
        FilledButton,
        'Publish',
      );

      expect(
        publishButton,
        findsOneWidget,
      );

      await tester.ensureVisible(publishButton);
      await tester.pumpAndSettle();

      await tester.tap(publishButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter the pet name.'),
        findsOneWidget,
      );

      expect(
        find.text('Please enter location.'),
        findsOneWidget,
      );

      expect(
        find.text('Please enter description.'),
        findsOneWidget,
      );

      expect(
        repository.createdListing,
        isNull,
      );
    },
  );

  testWidgets(
    'save draft creates listing with draft status',
    (tester) async {
      final repository = _FakeAdoptionListingRepository();

      await tester.pumpWidget(
        _buildPage(repository: repository),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Buddy',
      );

      final speciesDropdown =
          find.byType(DropdownButtonFormField<String>).at(0);

      await _selectDropdownValue(
        tester,
        speciesDropdown,
        'Dog',
      );

      final genderDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);

      await _selectDropdownValue(
        tester,
        genderDropdown,
        'Male',
      );

      final fields = find.byType(TextFormField);

      await tester.enterText(
        fields.at(3),
        'Colombo',
      );

      await tester.enterText(
        fields.at(4),
        'Friendly dog looking for a loving home.',
      );

      final saveDraftButton = find.widgetWithText(
        OutlinedButton,
        'Save Draft',
      );

      expect(
        saveDraftButton,
        findsOneWidget,
      );

      await tester.ensureVisible(saveDraftButton);
      await tester.pumpAndSettle();

      await tester.tap(saveDraftButton);
      await tester.pumpAndSettle();

      expect(
        repository.createdListing,
        isNotNull,
      );

      expect(
        repository.createdListing!.petName,
        'Buddy',
      );

      expect(
        repository.createdListing!.species,
        'Dog',
      );

      expect(
        repository.createdListing!.gender,
        'Male',
      );

      expect(
        repository.createdListing!.status,
        'draft',
      );
    },
  );

  testWidgets(
    'publish creates listing with available status',
    (tester) async {
      final repository = _FakeAdoptionListingRepository();

      await tester.pumpWidget(
        _buildPage(repository: repository),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Luna',
      );

      final speciesDropdown =
          find.byType(DropdownButtonFormField<String>).at(0);

      await _selectDropdownValue(
        tester,
        speciesDropdown,
        'Cat',
      );

      final genderDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);

      await _selectDropdownValue(
        tester,
        genderDropdown,
        'Male',
      );

      final fields = find.byType(TextFormField);

      await tester.enterText(
        fields.at(3),
        'Kandy',
      );

      await tester.enterText(
        fields.at(4),
        'Calm cat looking for a loving home.',
      );

      final publishButton = find.widgetWithText(
        FilledButton,
        'Publish',
      );

      expect(
        publishButton,
        findsOneWidget,
      );

      await tester.ensureVisible(publishButton);
      await tester.pumpAndSettle();

      await tester.tap(publishButton);
      await tester.pumpAndSettle();

      expect(
        repository.createdListing,
        isNotNull,
      );

      expect(
        repository.createdListing!.status,
        'available',
      );
    },
  );

  testWidgets(
    'edit mode pre-fills existing listing',
    (tester) async {
      final repository = _FakeAdoptionListingRepository();
      final listing = _createListing();

      await tester.pumpWidget(
        _buildPage(
          repository: repository,
          listing: listing,
        ),
      );

      expect(
        find.text('Edit Adoption Listing'),
        findsOneWidget,
      );

      expect(
        find.text('Buddy'),
        findsOneWidget,
      );

      expect(
        find.text('Labrador'),
        findsOneWidget,
      );

      expect(
        find.text('2 years'),
        findsOneWidget,
      );

      expect(
        find.text('Colombo'),
        findsOneWidget,
      );

      expect(
        find.text(
          'Friendly dog looking for a loving home.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'update saves edited listing',
    (tester) async {
      final repository = _FakeAdoptionListingRepository();
      final listing = _createListing();

      await tester.pumpWidget(
        _buildPage(
          repository: repository,
          listing: listing,
        ),
      );

      final nameField = find.byType(TextFormField).at(0);

      await tester.enterText(
        nameField,
        'Max',
      );

      final genderDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);

      await _selectDropdownValue(
        tester,
        genderDropdown,
        'Male',
      );

      final publishChangesButton = find.widgetWithText(
        FilledButton,
        'Publish Changes',
      );

      expect(
        publishChangesButton,
        findsOneWidget,
      );

      await tester.ensureVisible(publishChangesButton);
      await tester.pumpAndSettle();

      await tester.tap(publishChangesButton);
      await tester.pumpAndSettle();

      expect(
        repository.updatedListing,
        isNotNull,
      );

      expect(
        repository.updatedListing!.listingId,
        'listing-1',
      );

      expect(
        repository.updatedListing!.petName,
        'Max',
      );

      expect(
        repository.updatedListing!.status,
        'available',
      );
    },
  );

  testWidgets(
    'shows error when repository save fails',
    (tester) async {
      final repository = _FakeAdoptionListingRepository(
        createError: StateError('Network error'),
      );

      await tester.pumpWidget(
        _buildPage(repository: repository),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Buddy',
      );

      final speciesDropdown =
          find.byType(DropdownButtonFormField<String>).at(0);

      await _selectDropdownValue(
        tester,
        speciesDropdown,
        'Dog',
      );

      final genderDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);

      await _selectDropdownValue(
        tester,
        genderDropdown,
        'Male',
      );

      final fields = find.byType(TextFormField);

      await tester.enterText(
        fields.at(3),
        'Colombo',
      );

      await tester.enterText(
        fields.at(4),
        'Friendly dog looking for a loving home.',
      );

      final saveDraftButton = find.widgetWithText(
        OutlinedButton,
        'Save Draft',
      );

      expect(
        saveDraftButton,
        findsOneWidget,
      );

      await tester.ensureVisible(saveDraftButton);
      await tester.pumpAndSettle();

      await tester.tap(saveDraftButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Unable to save the adoption listing.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'shows error when updating listing fails',
    (tester) async {
      final repository = _FakeAdoptionListingRepository(
        updateError: StateError('Network error'),
      );

      await tester.pumpWidget(
        _buildPage(
          repository: repository,
          listing: _createListing(),
        ),
      );

      final publishChangesButton = find.widgetWithText(
        FilledButton,
        'Publish Changes',
      );

      expect(
        publishChangesButton,
        findsOneWidget,
      );

      await tester.ensureVisible(publishChangesButton);
      await tester.pumpAndSettle();

      await tester.tap(publishChangesButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to save the adoption listing.'),
        findsOneWidget,
      );

      expect(
        repository.updatedListing,
        isNull,
      );
    },
  );
}
