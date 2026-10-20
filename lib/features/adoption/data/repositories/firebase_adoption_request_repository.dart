import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/adoption_request.dart';
import '../../domain/repositories/adoption_request_decision_repository.dart';
import '../../domain/repositories/adoption_request_repository.dart';
import '../models/adoption_request_model.dart';

class FirebaseAdoptionRequestRepository
    implements AdoptionRequestRepository, AdoptionRequestDecisionRepository {
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
  Stream<List<AdoptionRequest>> watchMyRequests() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        const AdoptionRequestRepositoryException(
          'You must be signed in to view your adoption requests.',
        ),
      );
    }

    return _requestsCollection
        .where('requesterId', isEqualTo: user.uid)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AdoptionRequestModel.fromFirestore).toList(),
        );
  }

  @override
  Stream<List<AdoptionRequest>> watchReceivedRequests() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        const AdoptionRequestRepositoryException(
          'You must be signed in to view received adoption requests.',
        ),
      );
    }

    return _requestsCollection
        .where('providerId', isEqualTo: user.uid)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AdoptionRequestModel.fromFirestore).toList(),
        );
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

  @override
  Future<void> acceptRequest({
    required String requestId,
    String? providerNote,
  }) {
    return _decideRequest(
      requestId: requestId,
      decision: 'accepted',
      providerNote: providerNote,
    );
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    String? providerNote,
  }) {
    return _decideRequest(
      requestId: requestId,
      decision: 'rejected',
      providerNote: providerNote,
    );
  }

  Future<void> _decideRequest({
    required String requestId,
    required String decision,
    String? providerNote,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AdoptionRequestRepositoryException(
        'You must be signed in to review adoption requests.',
      );
    }

    if (decision != 'accepted' && decision != 'rejected') {
      throw const AdoptionRequestRepositoryException(
        'The requested adoption decision is invalid.',
      );
    }

    final requestReference = _requestsCollection.doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final document = await transaction.get(requestReference);

      if (!document.exists) {
        throw const AdoptionRequestRepositoryException(
          'The adoption request could not be found.',
        );
      }

      final data = document.data();
      if (data == null) {
        throw const AdoptionRequestRepositoryException(
          'The adoption request data is unavailable.',
        );
      }

      if (data['providerId'] != user.uid) {
        throw const AdoptionRequestRepositoryException(
          'You are not authorized to decide this adoption request.',
        );
      }

      if (data['status'] != 'pending') {
        throw const AdoptionRequestRepositoryException(
          'Only pending adoption requests can be accepted or rejected.',
        );
      }

      final updates = <String, Object>{
        'status': decision,
        'updatedAt': FieldValue.serverTimestamp(),
        if (decision == 'accepted') 'acceptedAt': FieldValue.serverTimestamp(),
        if (decision == 'rejected') 'closedAt': FieldValue.serverTimestamp(),
      };

      final trimmedNote = providerNote?.trim();
      if (trimmedNote != null && trimmedNote.isNotEmpty) {
        updates['providerNote'] = trimmedNote;
      }

      transaction.update(requestReference, updates);
    });
  }
}

class AdoptionRequestRepositoryException implements Exception {
  const AdoptionRequestRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
