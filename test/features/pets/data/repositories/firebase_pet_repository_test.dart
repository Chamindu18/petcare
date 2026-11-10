import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/pets/data/repositories/firebase_pet_repository.dart';

class _FailingFirestore extends FakeFirebaseFirestore {
  _FailingFirestore(this.failedCollection);

  final String failedCollection;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == failedCollection) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    return super.collection(path);
  }
}

void main() {
  const petId = 'pet-a';
  const ownerId = 'owner-a';

  FirebasePetRepository repository(FakeFirebaseFirestore db) =>
      FirebasePetRepository(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: ownerId),
        ),
        firestore: db,
      );

  Future<void> seedPet(FakeFirebaseFirestore db, {String imageUrl = ''}) =>
      db.collection('pets').doc(petId).set({
        'petId': petId,
        'ownerId': ownerId,
        'name': 'Milo',
        'species': 'Dog',
        'breed': 'Mixed',
        'dob': '2022-01-01T00:00:00.000',
        'gender': 'Male',
        'weight': 12.0,
        'imageUrl': imageUrl,
        'notes': '',
        'status': 'active',
      });

  Future<String?> petStatus(FakeFirebaseFirestore db) async =>
      (await db.collection('pets').doc(petId).get()).data()?['status']
          as String?;

  test(
    'unreferenced pet leaves active list while ownership anchor remains',
    () async {
      final db = FakeFirebaseFirestore();
      await seedPet(db, imageUrl: 'https://res.cloudinary.com/example.jpg');
      final pets = repository(db);

      await pets.deletePet(petId);

      expect(await petStatus(db), 'deleted');
      expect(
        (await db.collection('pets').doc(petId).get()).data()?['imageUrl'],
        '',
      );
      expect(await pets.getPets(), isEmpty);
      expect((await pets.getPetById(petId))?.ownerId, ownerId);
    },
  );

  test(
    'cross-owner deletion leaves pet and image reference unchanged',
    () async {
      final db = FakeFirebaseFirestore();
      await seedPet(db, imageUrl: 'https://res.cloudinary.com/example.jpg');
      final otherOwner = FirebasePetRepository(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'owner-b'),
        ),
        firestore: db,
      );

      await expectLater(
        otherOwner.deletePet(petId),
        throwsA(isA<PetRepositoryException>()),
      );
      final data = (await db.collection('pets').doc(petId).get()).data()!;
      expect(data['status'], 'active');
      expect(data['imageUrl'], 'https://res.cloudinary.com/example.jpg');
    },
  );

  for (final collection in const [
    'medical_conditions',
    'vaccinations',
    'treatments',
    'health_measurements',
  ]) {
    test('retains pet with linked $collection record', () async {
      final db = FakeFirebaseFirestore();
      await seedPet(db);
      await db.collection(collection).doc('record-a').set({'petId': petId});

      await expectLater(
        repository(db).deletePet(petId),
        throwsA(isA<PetRepositoryException>()),
      );
      expect(await petStatus(db), 'active');
    });
  }

  test('retains pet with historical appointment', () async {
    final db = FakeFirebaseFirestore();
    await seedPet(db);
    await db.collection('appointments').doc('appointment-a').set({
      'ownerId': ownerId,
      'petId': petId,
      'status': 'cancelled',
    });

    await expectLater(
      repository(db).deletePet(petId),
      throwsA(isA<PetRepositoryException>()),
    );
    expect(await petStatus(db), 'active');
  });

  for (final collection in const ['vaccinations', 'appointments']) {
    test('dependency read failure from $collection preserves pet', () async {
      final db = _FailingFirestore(collection);
      await seedPet(db);

      await expectLater(
        repository(db).deletePet(petId),
        throwsA(isA<FirebaseException>()),
      );
      expect(await petStatus(db), 'active');
    });
  }
}
