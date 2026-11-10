import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../appointments/data/models/appointment_model.dart';
import '../../../health/data/models/health_measurement_model.dart';
import '../../../health/data/models/medical_condition_model.dart';
import '../../../health/data/models/treatment_model.dart';
import '../../../health/data/models/vaccination_model.dart';
import '../../domain/entities/qr_health_passport.dart';
import '../../domain/repositories/qr_health_passport_repository.dart';
import '../models/qr_health_passport_model.dart';

class QrHealthPassportException implements Exception {
  const QrHealthPassportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Firestore implementation for appointment-bound QR passports.
///
/// Firestore Rules are the authorization boundary. The client performs the
/// same checks only to provide useful UI errors.
class FirebaseQrHealthPassportRepository implements QrHealthPassportRepository {
  FirebaseQrHealthPassportRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Random? secureRandom,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _random = secureRandom ?? Random.secure();

  // Rules allow at most 20 distinct document access calls per batch. Each
  // projection checks its source document, in addition to shared appointment,
  // pet, passport and veterinarian checks.
  static const _projectionLimit = 12;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Random _random;

  CollectionReference<Map<String, dynamic>> get _passports =>
      _firestore.collection('qr_health_passports');

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const QrHealthPassportException(
        'You must be signed in to use a health passport.',
      );
    }
    return uid;
  }

  @override
  Future<QrHealthPassport> createQrReference({
    required String petId,
    required String appointmentId,
  }) async {
    final uid = _uid;
    final appointmentSnapshot = await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .get();
    final appointment = appointmentSnapshot.data();

    if (!appointmentSnapshot.exists || appointment == null) {
      throw const QrHealthPassportException('Appointment was not found.');
    }
    if (appointment['ownerId'] != uid ||
        appointment['petId'] != petId ||
        appointment['status'] != 'confirmed') {
      throw const QrHealthPassportException(
        'This appointment is not eligible for a health passport.',
      );
    }

    final petSnapshot = await _firestore.collection('pets').doc(petId).get();
    final pet = petSnapshot.data();
    if (!petSnapshot.exists || pet == null || pet['ownerId'] != uid) {
      throw const QrHealthPassportException(
        'The selected pet is not available for this appointment.',
      );
    }

    final records = await Future.wait([
      _records('medical_conditions', petId),
      _records('vaccinations', petId),
      _records('treatments', petId),
      _records('health_measurements', petId),
    ]);
    final selected = <_PassportRecord>[
      for (var index = 0; index < records.length; index++)
        for (final document in records[index])
          _PassportRecord(_recordCollections[index], document),
    ];
    // Sort the complete owner-authorized result so the summary is independent
    // of Firestore's query order. Ties use collection and document ID.
    selected.sort((a, b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      if (byDate != 0) return byDate;
      final byCollection = a.collection.compareTo(b.collection);
      return byCollection != 0
          ? byCollection
          : a.document.id.compareTo(b.document.id);
    });
    _ensureSession(uid);

    final token = _newToken();
    final reference = _passports.doc(token);
    final batch = _firestore.batch();
    batch.set(reference, {
      'appointmentId': appointmentId,
      'petId': petId,
      'hospitalId': appointment['hospitalId'],
      'veterinarianId': appointment['vetId'],
      'status': 'active',
      'schemaVersion': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(reference.collection('pet').doc('summary'), {
      'name': pet['name'],
      'species': pet['species'],
      'breed': pet['breed'],
      'dob': pet['dob'],
    });

    for (final record in selected.take(_projectionLimit)) {
      // Rules enforce this relationship too; keep the client from preparing a
      // cross-pet projection even when given an inconsistent query result.
      if (record.document.data()['petId'] != petId) {
        throw const QrHealthPassportException(
          'The pet health records are inconsistent.',
        );
      }
      batch.set(
        reference.collection(record.collection).doc(record.document.id),
        record.document.data(),
      );
    }

    await batch.commit();
    _ensureSession(uid);
    final created = await reference.get();
    final data = created.data();
    if (data == null) {
      throw const QrHealthPassportException(
        'The health passport could not be created.',
      );
    }
    return QrHealthPassportModel.fromMap({...data, 'token': token});
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _records(
    String collection,
    String petId,
  ) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('petId', isEqualTo: petId)
        .get();
    return snapshot.docs;
  }

  static const _recordCollections = [
    'medical_conditions',
    'vaccinations',
    'treatments',
    'health_measurements',
  ];

  String _newToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  @override
  Future<QrHealthPassport?> verifyQrReference(String token) async {
    final uid = _uid;
    if (QrHealthPassportPayload.decode(QrHealthPassportPayload.encode(token)) ==
        null) {
      return null;
    }
    try {
      final snapshot = await _passports
          .doc(token)
          .get(const GetOptions(source: Source.server));
      _ensureSession(uid);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return QrHealthPassportModel.fromMap({...data, 'token': token});
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'not-found') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<QrHealthPassportData> getPassportData(String token) async {
    final uid = _uid;
    final passport = await verifyQrReference(token);
    if (passport == null) {
      throw const QrHealthPassportException(
        'This QR code is invalid, expired, revoked, or not authorized.',
      );
    }

    try {
      final reference = _passports.doc(token);
      final petSnapshot = await reference
          .collection('pet')
          .doc('summary')
          .get(const GetOptions(source: Source.server));
      final appointmentSnapshot = await _firestore
          .collection('appointments')
          .doc(passport.appointmentId)
          .get(const GetOptions(source: Source.server));
      final conditionSnapshot = await reference
          .collection('medical_conditions')
          .get(const GetOptions(source: Source.server));
      final vaccinationSnapshot = await reference
          .collection('vaccinations')
          .get(const GetOptions(source: Source.server));
      final treatmentSnapshot = await reference
          .collection('treatments')
          .get(const GetOptions(source: Source.server));
      final measurementSnapshot = await reference
          .collection('health_measurements')
          .get(const GetOptions(source: Source.server));
      _ensureSession(uid);

      final pet = petSnapshot.data();
      final appointment = appointmentSnapshot.data();
      if (pet == null || appointment == null) {
        throw const QrHealthPassportException(
          'The health passport information is unavailable.',
        );
      }

      return QrHealthPassportData(
        passport: passport,
        petName: pet['name'] as String,
        species: pet['species'] as String,
        breed: pet['breed'] as String,
        dateOfBirth: DateTime.parse(pet['dob'] as String),
        appointment: AppointmentModel.fromMap({
          ...appointment,
          'appointmentId': appointmentSnapshot.id,
        }),
        medicalConditions: conditionSnapshot.docs
            .map((document) => MedicalConditionModel.fromMap(document.data()))
            .toList(),
        vaccinations: vaccinationSnapshot.docs
            .map((document) => VaccinationModel.fromMap(document.data()))
            .toList(),
        treatments: treatmentSnapshot.docs
            .map((document) => TreatmentModel.fromMap(document.data()))
            .toList(),
        measurements: measurementSnapshot.docs
            .map((document) => HealthMeasurementModel.fromMap(document.data()))
            .toList(),
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'not-found') {
        throw const QrHealthPassportException(
          'This QR code is invalid, expired, revoked, or not authorized.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> revokeQrReference(String token) async {
    final uid = _uid;
    await _passports.doc(token).update({
      'status': 'revoked',
      'revokedAt': FieldValue.serverTimestamp(),
    });
    _ensureSession(uid);
  }

  void _ensureSession(String expectedUid) {
    if (_auth.currentUser?.uid != expectedUid) {
      throw const QrHealthPassportException(
        'Your session changed. Open the health passport again.',
      );
    }
  }
}

class _PassportRecord {
  _PassportRecord(this.collection, this.document);

  final String collection;
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  DateTime get createdAt =>
      DateTime.parse(document.data()['createdAt'] as String);
}
