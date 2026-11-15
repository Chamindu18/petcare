import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/pets/domain/entities/pet.dart';
import 'package:petcare/features/pets/domain/repositories/pet_image_repository.dart';
import 'package:petcare/features/pets/domain/repositories/pet_repository.dart';
import 'package:petcare/features/pets/domain/usecases/create_pet.dart';
import 'package:petcare/features/pets/domain/usecases/delete_pet.dart';
import 'package:petcare/features/pets/domain/usecases/delete_pet_image.dart';
import 'package:petcare/features/pets/domain/usecases/get_pets.dart';
import 'package:petcare/features/pets/domain/usecases/update_pet.dart';
import 'package:petcare/features/pets/domain/usecases/upload_pet_image.dart';
import 'package:petcare/features/pets/presentation/providers/pets_controller.dart';
import 'package:petcare/features/pets/presentation/pages/add_edit_pet_page.dart';

const oldUrl = 'https://res.cloudinary.com/test/old.jpg';
const newUrl = 'https://res.cloudinary.com/test/new.jpg';
final bytes = Uint8List.fromList([1, 2, 3]);

Pet pet([String imageUrl = '']) => Pet(
  petId: 'pet-a',
  ownerId: 'owner-a',
  name: 'Milo',
  species: 'Dog',
  breed: 'Mixed',
  dob: DateTime(2022),
  gender: 'Male',
  weight: 12,
  imageUrl: imageUrl,
  notes: '',
  status: 'active',
);

class _Pets implements PetRepository {
  _Pets([Pet? initial]) : stored = initial;
  Pet? stored;
  bool failUpdate = false;
  bool failDelete = false;

  @override
  Future<Pet> createPet(Pet value) async {
    stored = pet(value.imageUrl);
    return stored!;
  }

  @override
  Future<List<Pet>> getPets() async => stored == null ? [] : [stored!];

  @override
  Future<Pet?> getPetById(String id) async => stored;

  @override
  Future<void> updatePet(Pet value) async {
    if (failUpdate) throw StateError('Firestore update failed');
    stored = value;
  }

  @override
  Future<void> deletePet(String id) async {
    if (failDelete) throw StateError('Firestore delete failed');
    stored = null;
  }
}

class _Images implements PetImageRepository {
  bool failUpload = false;
  int deletionAttempts = 0;

  @override
  Future<String> uploadPetImage({
    required String petId,
    required Uint8List bytes,
  }) async {
    if (failUpload) throw StateError('Cloudinary upload failed');
    return newUrl;
  }

  @override
  Future<void> deletePetImage({required String imageUrl}) async {
    deletionAttempts++;
    throw StateError('Hosted deletion unavailable');
  }
}

PetsController _controller(_Pets pets, _Images images) => PetsController(
  CreatePet(pets),
  GetPets(pets),
  UpdatePet(pets),
  DeletePet(pets),
  UploadPetImage(images),
  DeletePetImage(images),
);

void main() {
  test('upload saves the returned photo URL', () async {
    final pets = _Pets();
    final subject = _controller(pets, _Images());
    await subject.create(pet(), imageBytes: bytes);
    expect(subject.errorMessage, isNull);
    expect(pets.stored?.imageUrl, newUrl);
  });

  test(
    'replacement saves new URL despite unavailable hosted deletion',
    () async {
      final pets = _Pets(pet(oldUrl));
      final images = _Images();
      final subject = _controller(pets, images);
      await subject.loadPets();
      await subject.update(pet(oldUrl), imageBytes: bytes);
      expect(subject.errorMessage, isNull);
      expect(pets.stored?.imageUrl, newUrl);
      expect(images.deletionAttempts, 1);
    },
  );

  test(
    'removal clears reference despite unavailable hosted deletion',
    () async {
      final pets = _Pets(pet(oldUrl));
      final subject = _controller(pets, _Images());
      await subject.loadPets();
      await subject.update(pet(oldUrl), removeImage: true);
      expect(subject.errorMessage, isNull);
      expect(pets.stored?.imageUrl, '');
    },
  );

  test('Cloudinary upload failure leaves old Firestore reference', () async {
    final pets = _Pets(pet(oldUrl));
    final images = _Images()..failUpload = true;
    final subject = _controller(pets, images);
    await subject.loadPets();
    await subject.update(pet(oldUrl), imageBytes: bytes);
    expect(subject.errorMessage, isNotNull);
    expect(pets.stored?.imageUrl, oldUrl);
  });

  test(
    'Firestore update failure leaves old reference and attempts cleanup',
    () async {
      final pets = _Pets(pet(oldUrl))..failUpdate = true;
      final images = _Images();
      final subject = _controller(pets, images);
      await subject.loadPets();
      await subject.update(pet(oldUrl), imageBytes: bytes);
      expect(subject.errorMessage, isNotNull);
      expect(pets.stored?.imageUrl, oldUrl);
      expect(images.deletionAttempts, 1);
    },
  );

  test('failed pet deletion preserves pet and image reference', () async {
    final pets = _Pets(pet(oldUrl))..failDelete = true;
    final images = _Images();
    final subject = _controller(pets, images);
    await subject.loadPets();
    await subject.delete('pet-a');
    expect(subject.errorMessage, isNotNull);
    expect(pets.stored?.imageUrl, oldUrl);
    expect(images.deletionAttempts, 0);
  });

  testWidgets('removing a photo discloses hosted retention', (tester) async {
    final subject = _controller(_Pets(pet(oldUrl)), _Images());
    await tester.pumpWidget(
      MaterialApp(
        home: AddEditPetPage(controller: subject, pet: pet(oldUrl)),
      ),
    );
    await tester.ensureVisible(find.byTooltip('Remove photo'));
    await tester.tap(find.byTooltip('Remove photo'));
    await tester.pump();
    expect(
      find.textContaining('may remain accessible at its hosted URL'),
      findsOneWidget,
    );
  });
}
