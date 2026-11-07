import 'dart:math';

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
}
