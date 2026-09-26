import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/adoption_request.dart';
import '../../domain/repositories/adoption_request_repository.dart';
import '../models/adoption_request_model.dart';

class FirebaseAdoptionRequestRepository implements AdoptionRequestRepository {
  FirebaseAdoptionRequestRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection('adoption_requests');

  void _ensureSignedIn() {
    if (_auth.currentUser == null) {
      throw const AdoptionRequestRepositoryException(
        'You must be signed in to submit an adoption request.',
      );
    }
  }

  @override
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AdoptionRequestRepositoryException(
        'You must be signed in to submit an adoption request.',
      );
    }

    final now = FieldValue.serverTimestamp();

    await _requestsCollection.add({
      'listingId': listingId,
      'requesterId': user.uid,
      'providerId': providerId,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
      'status': 'pending',
      'submittedAt': now,
      'updatedAt': now,
    });
  }

  @override
  Stream<AdoptionRequest?> watchRequest({required String requestId}) {
    try {
      _ensureSignedIn();
    } catch (error) {
      return Stream.error(error);
    }

    return _requestsCollection.doc(requestId).snapshots().map((document) {
      if (!document.exists) {
        return null;
      }

      return AdoptionRequestModel.fromFirestore(document);
    });
  }
}

class AdoptionRequestRepositoryException implements Exception {
  const AdoptionRequestRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
