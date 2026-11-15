import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/qr_health_passport/data/repositories/firebase_qr_health_passport_repository.dart';
import 'package:petcare/features/qr_health_passport/domain/entities/qr_health_passport.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseQrHealthPassportRepository repository;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'owner-a'),
      signedIn: true,
    );
    repository = FirebaseQrHealthPassportRepository(
      auth: auth,
      firestore: firestore,
      secureRandom: Random(7),
    );
    await firestore.collection('appointments').doc('appointment-a').set({
      'ownerId': 'owner-a',
      'petId': 'pet-a',
      'hospitalId': 'hospital-a',
      'serviceId': 'service-a',
      'vetId': 'vet-a',
      'dateTime': DateTime(2026, 11, 7).toIso8601String(),
      'reason': 'Checkup',
      'status': 'confirmed',
      'createdAt': DateTime(2026, 11, 1).toIso8601String(),
    });
    await firestore.collection('pets').doc('pet-a').set({
      'petId': 'pet-a',
      'ownerId': 'owner-a',
      'name': 'Milo',
      'species': 'Dog',
      'breed': 'Mixed',
      'dob': DateTime(2022).toIso8601String(),
      'gender': 'male',
      'weight': 12,
      'imageUrl': '',
      'notes': '',
      'status': 'active',
    });
  });

  test(
    'creates an opaque 256-bit reference with server-derived expiry',
    () async {
      final passport = await repository.createQrReference(
        petId: 'pet-a',
        appointmentId: 'appointment-a',
      );

      expect(passport.token, hasLength(43));
      expect(
        passport.expiresAt.difference(passport.createdAt),
        qrHealthPassportValidity,
      );

      final payload = QrHealthPassportPayload.encode(passport.token);
      expect(QrHealthPassportPayload.decode(payload), passport.token);
      expect(payload, isNot(contains('pet-a')));
      expect(payload, isNot(contains('appointment-a')));
      expect(payload, isNot(contains('Milo')));

      final stored =
          (await firestore
                  .collection('qr_health_passports')
                  .doc(passport.token)
                  .get())
              .data()!;
      expect(stored, isNot(contains('expiresAt')));
      expect(stored['status'], 'active');
    },
  );

  test('rejects unrelated or ineligible appointments before writing', () async {
    await firestore.collection('appointments').doc('appointment-a').update({
      'status': 'cancelled',
    });

    await expectLater(
      repository.createQrReference(
        petId: 'pet-a',
        appointmentId: 'appointment-a',
      ),
      throwsA(isA<QrHealthPassportException>()),
    );
    expect(
      (await firestore.collection('qr_health_passports').get()).docs,
      isEmpty,
    );
  });

  test('revokes an active reference', () async {
    final passport = await repository.createQrReference(
      petId: 'pet-a',
      appointmentId: 'appointment-a',
    );
    await repository.revokeQrReference(passport.token);

    final stored =
        (await firestore
                .collection('qr_health_passports')
                .doc(passport.token)
                .get())
            .data()!;
    expect(stored['status'], 'revoked');
    expect(stored['revokedAt'], isNotNull);
  });

  Future<void> addConditions(int count, {String petId = 'pet-a'}) async {
    for (var i = 0; i < count; i++) {
      final id = 'condition-${i.toString().padLeft(2, '0')}';
      await firestore.collection('medical_conditions').doc(id).set({
        'conditionId': id,
        'petId': petId,
        'name': id,
        'status': 'active',
        'source': 'owner-reported',
        'diagnosisDate': '2026-01-01T00:00:00.000Z',
        'notes': '',
        'createdAt': DateTime.utc(
          2026,
          1,
          1,
        ).add(Duration(days: i)).toIso8601String(),
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });
    }
  }

  Future<List<String>> projectedIds(String token) async =>
      (await firestore
              .collection('qr_health_passports')
              .doc(token)
              .collection('medical_conditions')
              .get())
          .docs
          .map((doc) => doc.id)
          .toList();

  for (final count in [3, 12, 13]) {
    test('projects a bounded summary from $count records', () async {
      await addConditions(count);
      final passport = await repository.createQrReference(
        petId: 'pet-a',
        appointmentId: 'appointment-a',
      );
      final ids = await projectedIds(passport.token);
      expect(ids, hasLength(count.clamp(0, 12)));
      if (count == 13) {
        expect(ids, isNot(contains('condition-00')));
        expect(ids, contains('condition-12'));
      }
    });
  }

  test('selection is deterministic for equal timestamps', () async {
    await addConditions(13);
    for (var i = 0; i < 13; i++) {
      await firestore
          .collection('medical_conditions')
          .doc('condition-${i.toString().padLeft(2, '0')}')
          .update({'createdAt': '2026-01-01T00:00:00.000Z'});
    }
    final first = await repository.createQrReference(
      petId: 'pet-a',
      appointmentId: 'appointment-a',
    );
    final second = await repository.createQrReference(
      petId: 'pet-a',
      appointmentId: 'appointment-a',
    );
    expect(await projectedIds(first.token), await projectedIds(second.token));
    expect(await projectedIds(first.token), contains('condition-00'));
    expect(await projectedIds(first.token), isNot(contains('condition-12')));
  });

  test('newer records take priority across health categories', () async {
    await addConditions(12);
    await firestore.collection('vaccinations').doc('vaccine-a').set({
      'vaccinationId': 'vaccine-a',
      'petId': 'pet-a',
      'name': 'Rabies',
      'dateGiven': '2026-02-01T00:00:00.000Z',
      'nextDueDate': null,
      'providerId': null,
      'notes': '',
      'createdAt': '2026-02-01T00:00:00.000Z',
      'updatedAt': '2026-02-01T00:00:00.000Z',
    });
    final passport = await repository.createQrReference(
      petId: 'pet-a',
      appointmentId: 'appointment-a',
    );
    expect(await projectedIds(passport.token), hasLength(11));
    expect(await projectedIds(passport.token), isNot(contains('condition-00')));
    final vaccines = await firestore
        .collection('qr_health_passports')
        .doc(passport.token)
        .collection('vaccinations')
        .get();
    expect(vaccines.docs.single.id, 'vaccine-a');
  });

  test('another pet\'s records never enter the projection', () async {
    await addConditions(3);
    await firestore.collection('medical_conditions').doc('other-pet').set({
      ...(await firestore
              .collection('medical_conditions')
              .doc('condition-00')
              .get())
          .data()!,
      'conditionId': 'other-pet',
      'petId': 'pet-b',
    });
    final passport = await repository.createQrReference(
      petId: 'pet-a',
      appointmentId: 'appointment-a',
    );
    expect(await projectedIds(passport.token), hasLength(3));
    expect(await projectedIds(passport.token), isNot(contains('other-pet')));
  });

  test(
    'another owner cannot generate a passport for this appointment',
    () async {
      final otherOwner = FirebaseQrHealthPassportRepository(
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'owner-b'),
          signedIn: true,
        ),
        firestore: firestore,
      );
      await expectLater(
        otherOwner.createQrReference(
          petId: 'pet-a',
          appointmentId: 'appointment-a',
        ),
        throwsA(isA<QrHealthPassportException>()),
      );
      expect(
        (await firestore.collection('qr_health_passports').get()).docs,
        isEmpty,
      );
    },
  );

  test('failed Firestore write does not produce a passport', () async {
    final failingFirestore = _FailingBatchFirestore();
    for (final collection in ['appointments', 'pets']) {
      final id = collection == 'appointments' ? 'appointment-a' : 'pet-a';
      final source = await firestore.collection(collection).doc(id).get();
      await failingFirestore.collection(collection).doc(id).set(source.data()!);
    }
    failingFirestore.failBatch = true;
    final failing = FirebaseQrHealthPassportRepository(
      auth: MockFirebaseAuth(
        mockUser: MockUser(uid: 'owner-a'),
        signedIn: true,
      ),
      firestore: failingFirestore,
    );
    await expectLater(
      failing.createQrReference(petId: 'pet-a', appointmentId: 'appointment-a'),
      throwsA(isA<FirebaseException>()),
    );
  });
}

class _FailingBatchFirestore extends FakeFirebaseFirestore {
  bool failBatch = false;

  @override
  WriteBatch batch() {
    if (failBatch) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    return super.batch();
  }
}
