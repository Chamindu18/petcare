import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/adoption_request.dart';
import '../../domain/repositories/adoption_request_decision_repository.dart';
import '../../domain/repositories/adoption_request_repository.dart';
import '../../domain/repositories/adoption_request_withdrawal_repository.dart';
import '../models/adoption_request_model.dart';

class FirebaseAdoptionRequestRepository
    implements
        AdoptionRequestRepository,
        AdoptionRequestDecisionRepository,
        AdoptionRequestWithdrawalRepository {
  FirebaseAdoptionRequestRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection('adoption_requests');
  CollectionReference<Map<String, dynamic>> get _listingsCollection =>
      _firestore.collection('adoption_listings');

  Future<String> _roleFor(String uid) async {
    final profile = await _firestore.collection('users').doc(uid).get();
    final role = profile.data()?['role'];
    if (role is! String) {
      throw const AdoptionRequestRepositoryException(
        'Your account role could not be verified.',
      );
    }
    return role;
  }

  @override
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? recipientId,
    String recipientType = 'adoption_provider',
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AdoptionRequestRepositoryException(
        'You must be signed in to submit an adoption request.',
      );
    }
    if (await _roleFor(user.uid) != 'owner') {
      throw const AdoptionRequestRepositoryException(
        'Only pet owners can submit adoption requests.',
      );
    }

    final requestReference = _requestsCollection.doc();
    final listingReference = _listingsCollection.doc(listingId);
    final suppliedRecipient = recipientId ?? providerId;

    await _firestore.runTransaction((transaction) async {
      final listingDocument = await transaction.get(listingReference);
      final listing = listingDocument.data();
      if (!listingDocument.exists || listing == null) {
        throw const AdoptionRequestRepositoryException(
          'The selected adoption listing no longer exists.',
        );
      }
      if (listing['status'] != 'available') {
        throw const AdoptionRequestRepositoryException(
          'This adoption listing is not available for new requests.',
        );
      }

      final listingOwnerType =
          listing['listingOwnerType'] as String? ?? 'adoption_provider';
      final legacyProviderId = listing['providerId'] as String? ?? '';
      final listingOwnerId =
          listing['listingOwnerId'] as String? ?? legacyProviderId;
      if (listingOwnerType != 'owner' &&
          listingOwnerType != 'adoption_provider') {
        throw const AdoptionRequestRepositoryException(
          'The listing owner is invalid.',
        );
      }
      if (listingOwnerId.isEmpty || listingOwnerId == user.uid) {
        throw const AdoptionRequestRepositoryException(
          'You cannot submit an adoption request to your own listing.',
        );
      }
      if (suppliedRecipient != listingOwnerId ||
          recipientType != listingOwnerType) {
        throw const AdoptionRequestRepositoryException(
          'The listing recipient does not match the selected listing.',
        );
      }

      final normalizedMessage = message?.trim();
      transaction.set(requestReference, {
        'listingId': listingId,
        'requesterId': user.uid,
        'recipientId': listingOwnerId,
        'recipientType': listingOwnerType,
        // Retain the legacy alias for provider documents/queries only.
        if (listingOwnerType == 'adoption_provider')
          'providerId': listingOwnerId,
        if (normalizedMessage != null && normalizedMessage.isNotEmpty)
          'message': normalizedMessage,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
        .map(_mapRequests);
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

    return Stream.fromFuture(_roleFor(user.uid)).asyncExpand((role) {
      // Both inboxes use canonical recipient fields. Valid legacy provider
      // requests are normalized by the trusted backfill before deployment;
      // malformed/unbackfilled requests are intentionally not exposed.
      final query = role == 'owner' || role == 'adoption_provider'
          ? _requestsCollection
              .where('recipientId', isEqualTo: user.uid)
              .where('recipientType', isEqualTo: role)
          : null;
      if (query == null) {
        return Stream<List<AdoptionRequest>>.error(
          const AdoptionRequestRepositoryException(
            'This account cannot receive adoption requests.',
          ),
        );
      }
      return query
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map(_mapRequests);
    });
  }

  @override
  Stream<AdoptionRequest?> watchRequest({required String requestId}) {
    if (_auth.currentUser == null) {
      return Stream.error(
        const AdoptionRequestRepositoryException(
          'You must be signed in to view adoption requests.',
        ),
      );
    }

    return _requestsCollection.doc(requestId).snapshots().map((document) {
      if (!document.exists) return null;
      return AdoptionRequestModel.fromFirestore(document);
    });
  }

  @override
  Future<void> withdrawRequest({required String requestId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AdoptionRequestRepositoryException(
        'You must be signed in to withdraw an adoption request.',
      );
    }
    if (await _roleFor(user.uid) != 'owner') {
      throw const AdoptionRequestRepositoryException(
        'Only the requesting owner can withdraw an adoption request.',
      );
    }

    final requestReference = _requestsCollection.doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final document = await transaction.get(requestReference);
      final data = document.data();
      if (!document.exists || data == null) {
        throw const AdoptionRequestRepositoryException(
          'The adoption request could not be found.',
        );
      }
      if (data['requesterId'] != user.uid) {
        throw const AdoptionRequestRepositoryException(
          'You are not authorized to withdraw this request.',
        );
      }
      if (data['status'] != 'pending') {
        throw const AdoptionRequestRepositoryException(
          'Only pending adoption requests can be withdrawn.',
        );
      }
      transaction.update(requestReference, {
        'status': 'withdrawn',
        'updatedAt': FieldValue.serverTimestamp(),
        'closedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> acceptRequest({
    required String requestId,
    String? providerNote,
  }) => _decideRequest(
    requestId: requestId,
    decision: 'accepted',
    providerNote: providerNote,
  );

  @override
  Future<void> rejectRequest({
    required String requestId,
    String? providerNote,
  }) => _decideRequest(
    requestId: requestId,
    decision: 'rejected',
    providerNote: providerNote,
  );

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
    final role = await _roleFor(user.uid);
    if (role != 'owner' && role != 'adoption_provider') {
      throw const AdoptionRequestRepositoryException(
        'This account cannot decide adoption requests.',
      );
    }

    final requestReference = _requestsCollection.doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final document = await transaction.get(requestReference);
      final data = document.data();
      if (!document.exists || data == null) {
        throw const AdoptionRequestRepositoryException(
          'The adoption request could not be found.',
        );
      }
      // Decisions require trusted canonical recipient metadata. Legacy
      // providerId alone is not authorization evidence; the trusted backfill
      // must validate the linked listing before a legacy request is actionable.
      final recipientId = data['recipientId'] as String? ?? '';
      final recipientType = data['recipientType'] as String? ?? '';
      if (recipientId != user.uid || recipientType != role) {
        throw const AdoptionRequestRepositoryException(
          'You are not authorized to decide this adoption request.',
        );
      }
      if (data['status'] != 'pending') {
        throw const AdoptionRequestRepositoryException(
          'Only pending adoption requests can be accepted or rejected.',
        );
      }

      final listingReference = _listingsCollection.doc(data['listingId'] as String);
      final listingDocument = await transaction.get(listingReference);
      final listing = listingDocument.data();
      if (!listingDocument.exists || listing == null) {
        throw const AdoptionRequestRepositoryException(
          'The related adoption listing could not be found.',
        );
      }
      final listingType =
          listing['listingOwnerType'] as String? ?? 'adoption_provider';
      final listingOwnerId = listing['listingOwnerId'] as String? ??
          listing['providerId'] as String? ?? '';
      if (listingOwnerId != user.uid || listingType != role) {
        throw const AdoptionRequestRepositoryException(
          'You no longer own this adoption listing.',
        );
      }
      if (decision == 'accepted' && listing['status'] != 'available') {
        throw const AdoptionRequestRepositoryException(
          'This adoption listing is no longer available, so the request cannot be accepted.',
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

  List<AdoptionRequest> _mapRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs.map(AdoptionRequestModel.fromFirestore).toList();
}

class AdoptionRequestRepositoryException implements Exception {
  const AdoptionRequestRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
