import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/pets/domain/entities/pet.dart';
import 'package:petcare/features/pets/domain/repositories/pet_repository.dart';
import 'package:petcare/features/pets/domain/usecases/create_pet.dart';
import 'package:petcare/features/pets/domain/usecases/delete_pet.dart';
import 'package:petcare/features/pets/domain/usecases/get_pets.dart';
import 'package:petcare/features/pets/domain/usecases/update_pet.dart';
import 'package:petcare/features/pets/presentation/pages/add_edit_pet_page.dart';
import 'package:petcare/features/pets/presentation/providers/pets_controller.dart';

Pet _existingPet() => Pet(
  petId: 'pet-1',
  ownerId: 'owner-1',
  name: 'Milo',
  species: 'Dog',
  breed: 'Mixed',
  dob: DateTime(2022, 3, 4),
  gender: 'Male',
  weight: 12,
  imageUrl: '',
  notes: 'Old note',
  status: 'active',
);

// Mirrors the repository boundary: only persistence assigns the new identity.
class _PetRepository implements PetRepository {
  _PetRepository([Pet? initial]) : stored = initial;

  Pet? stored;
  Pet? createInput;
  Pet? updateInput;
  int creates = 0;
  int updates = 0;
  Completer<void>? pendingCreate;
  Completer<void>? pendingUpdate;
  bool failCreate = false;
  bool failUpdate = false;

  @override
  Future<Pet> createPet(Pet pet) async {
    creates++;
    createInput = pet;
    if (pendingCreate case final pending?) await pending.future;
    if (failCreate) throw StateError('private persistence detail');
    stored = Pet(
      petId: 'pet-2',
      ownerId: 'owner-1',
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      dob: pet.dob,
      gender: pet.gender,
      weight: pet.weight,
      imageUrl: pet.imageUrl,
      notes: pet.notes,
      status: pet.status,
    );
    return stored!;
  }

  @override
  Future<void> updatePet(Pet pet) async {
    updates++;
    updateInput = pet;
    if (pendingUpdate case final pending?) await pending.future;
    if (failUpdate) throw StateError('private persistence detail');
    stored = pet;
  }

  @override
  Future<List<Pet>> getPets() async => stored == null ? [] : [stored!];

  @override
  Future<Pet?> getPetById(String petId) async => stored;

  @override
  Future<void> deletePet(String petId) async => stored = null;
}

PetsController _controller(_PetRepository repository) => PetsController(
  CreatePet(repository),
  GetPets(repository),
  UpdatePet(repository),
  DeletePet(repository),
);

Future<ValueNotifier<int>> _openForm(
  WidgetTester tester,
  PetsController controller, {
  Pet? pet,
}) async {
  final returns = ValueNotifier<int>(0);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AddEditPetPage(controller: controller, pet: pet),
                    ),
                  )
                  .then((_) => returns.value++);
            },
            child: const Text('Open form'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open form'));
  await tester.pumpAndSettle();
  return returns;
}

Future<void> _enter(WidgetTester tester, String hint, String value) async {
  final field = find.widgetWithText(TextFormField, hint);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

Future<void> _choose(WidgetTester tester, String hint, String value) async {
  final field = find.widgetWithText(DropdownButtonFormField<String>, hint);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Future<void> _fillCreateForm(WidgetTester tester) async {
  await _enter(tester, 'e.g. Milo', '  Luna  ');
  await _choose(tester, 'Select species', 'Cat');
  await _enter(tester, 'e.g. Golden Retriever', '  Mixed  ');
  await tester.ensureVisible(find.text('Select date'));
  await tester.tap(find.text('Select date'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Select').last);
  await tester.pumpAndSettle();
  await _choose(tester, 'Select gender', 'Female');
  await _enter(tester, 'e.g. 12.5', '4.5');
}

Future<void> _save(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  testWidgets(
    'create shows fields and persists trimmed values and optional blanks',
    (tester) async {
      final repository = _PetRepository();
      final controller = _controller(repository);
      final returns = await _openForm(tester, controller);
      expect(find.text('Add Pet'), findsOneWidget);
      expect(
        find.textContaining('Pet Name', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Create Pet'), findsOneWidget);
      await _fillCreateForm(tester);
      await _save(tester, 'Create Pet');
      await tester.pumpAndSettle();

      expect(repository.creates, 1);
      expect(repository.updates, 0);
      expect(repository.createInput?.petId, '');
      expect(repository.createInput?.ownerId, '');
      expect(repository.createInput?.name, 'Luna');
      expect(repository.createInput?.species, 'Cat');
      expect(repository.createInput?.breed, 'Mixed');
      expect(repository.createInput?.gender, 'Female');
      expect(repository.createInput?.weight, 4.5);
      expect(repository.createInput?.notes, '');
      expect(repository.createInput?.status, 'active');
      expect(repository.createInput?.dob.isAfter(DateTime(1900)), isTrue);
      expect(controller.pets.single.petId, 'pet-2');
      expect(controller.pets.single.ownerId, 'owner-1');
      expect(returns.value, 1);
      expect(find.text('Open form'), findsOneWidget);
    },
  );

  testWidgets(
    'edit prepopulates, updates, and preserves identity and ownership',
    (tester) async {
      final original = _existingPet();
      final repository = _PetRepository(original);
      final controller = _controller(repository);
      await controller.loadPets();
      final returns = await _openForm(tester, controller, pet: original);
      expect(find.text('Edit Pet'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('04/03/2022'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Milo'), findsOneWidget);
      await _enter(tester, 'Milo', 'Mila');
      await _enter(tester, 'Old note', 'Updated note');
      await _save(tester, 'Save Changes');
      await tester.pumpAndSettle();

      expect(repository.creates, 0);
      expect(repository.updates, 1);
      expect(repository.updateInput?.petId, original.petId);
      expect(repository.updateInput?.ownerId, original.ownerId);
      expect(repository.updateInput?.status, original.status);
      expect(repository.updateInput?.name, 'Mila');
      expect(repository.updateInput?.notes, 'Updated note');
      expect(controller.pets.single.name, 'Mila');
      expect(returns.value, 1);
    },
  );

  testWidgets(
    'required fields, missing date, and invalid weights block writes',
    (tester) async {
      final repository = _PetRepository();
      final controller = _controller(repository);
      await _openForm(tester, controller);
      await _save(tester, 'Create Pet');
      expect(find.text("Please enter your pet's name"), findsOneWidget);
      expect(find.text("Please select your pet's species"), findsOneWidget);
      expect(find.text("Please select your pet's breed"), findsOneWidget);
      expect(find.text("Please select your pet's gender"), findsOneWidget);
      expect(find.text("Please enter your pet's weight"), findsOneWidget);
      expect(repository.creates, 0);

      await _enter(tester, 'e.g. Milo', 'Luna');
      await _choose(tester, 'Select species', 'Cat');
      await _enter(tester, 'e.g. Golden Retriever', 'Mixed');
      await _choose(tester, 'Select gender', 'Female');
      for (final invalid in ['abc', '0', '-2']) {
        await _enter(tester, 'e.g. 12.5', invalid);
        await _save(tester, 'Create Pet');
        expect(find.text('Please enter a valid weight'), findsOneWidget);
        expect(repository.creates, 0);
      }
      await _enter(tester, 'e.g. 12.5', '4');
      await _save(tester, 'Create Pet');
      expect(
        find.text("Please select your pet's date of birth."),
        findsOneWidget,
      );
      expect(repository.creates, 0);
    },
  );

  for (final editing in [false, true]) {
    testWidgets('abandon ${editing ? 'edit' : 'create'} without writing', (
      tester,
    ) async {
      final existing = editing ? _existingPet() : null;
      final repository = _PetRepository(existing);
      final controller = _controller(repository);
      final returns = await _openForm(tester, controller, pet: existing);
      await _enter(tester, editing ? 'Milo' : 'e.g. Milo', 'Unsaved');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(returns.value, 1);
      expect(repository.creates, 0);
      expect(repository.updates, 0);
      expect(repository.stored?.name, existing?.name);
    });
  }

  testWidgets(
    'reopening abandoned create form starts with fresh fields and date',
    (tester) async {
      final repository = _PetRepository();
      final controller = _controller(repository);
      final returns = await _openForm(tester, controller);
      await _enter(tester, 'e.g. Milo', 'Unsaved');
      await tester.ensureVisible(find.text('Select date'));
      await tester.tap(find.text('Select date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'e.g. Milo'), findsOneWidget);
      expect(find.text('Select date'), findsOneWidget);
      expect(returns.value, 1);
      expect(repository.creates, 0);
    },
  );

  for (final editing in [false, true]) {
    testWidgets(
      'pending ${editing ? 'update' : 'create'} submits once and pops once',
      (tester) async {
        final existing = editing ? _existingPet() : null;
        final repository = _PetRepository(existing);
        final pending = Completer<void>();
        if (editing) {
          repository.pendingUpdate = pending;
        } else {
          repository.pendingCreate = pending;
        }
        final controller = _controller(repository);
        final returns = await _openForm(tester, controller, pet: existing);
        if (!editing) await _fillCreateForm(tester);
        final label = editing ? 'Save Changes' : 'Create Pet';
        await _save(tester, label);
        expect(controller.isLoading, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        expect(editing ? repository.updates : repository.creates, 1);
        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        await tester.pump();
        expect(editing ? repository.updates : repository.creates, 1);
        pending.complete();
        await tester.pumpAndSettle();
        expect(controller.isLoading, isFalse);
        expect(returns.value, 1);
      },
    );
  }

  for (final editing in [false, true]) {
    testWidgets(
      'failed ${editing ? 'update' : 'create'} retains form and retries safely',
      (tester) async {
        final existing = editing ? _existingPet() : null;
        final repository = _PetRepository(existing);
        if (editing) {
          repository.failUpdate = true;
        } else {
          repository.failCreate = true;
        }
        final controller = _controller(repository);
        if (editing) await controller.loadPets();
        final returns = await _openForm(tester, controller, pet: existing);
        if (editing) {
          await _enter(tester, 'Milo', 'Mila');
        } else {
          await _fillCreateForm(tester);
        }
        final label = editing ? 'Save Changes' : 'Create Pet';
        await _save(tester, label);
        await tester.pump();
        expect(
          find.text('Unable to complete the pet operation.'),
          findsOneWidget,
        );
        expect(find.text('private persistence detail'), findsNothing);
        expect(find.text(label), findsOneWidget);
        expect(returns.value, 0);
        expect(repository.stored?.name, existing?.name);
        expect(
          controller.pets.map((pet) => pet.name),
          editing ? ['Milo'] : isEmpty,
        );
        repository.failCreate = false;
        repository.failUpdate = false;
        await _save(tester, label);
        await tester.pumpAndSettle();
        expect(editing ? repository.updates : repository.creates, 2);
        expect(returns.value, 1);
      },
    );
  }

  testWidgets('completion after leaving form does not navigate again', (
    tester,
  ) async {
    final repository = _PetRepository();
    final pending = Completer<void>();
    repository.pendingCreate = pending;
    final controller = _controller(repository);
    final returns = await _openForm(tester, controller);
    await _fillCreateForm(tester);
    await _save(tester, 'Create Pet');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(returns.value, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(returns.value, 1);
    expect(controller.pets.single.name, 'Luna');
  });
}
