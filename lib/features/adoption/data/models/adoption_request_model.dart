import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/adoption_request.dart';

class AdoptionRequestModel extends AdoptionRequest {
  const AdoptionRequestModel({
    required super.requestId,
    required super.listingId,
    required super.requesterId,
    required super.providerId,
    super.message,
    required super.status,
    required super.submittedAt,
    required super.updatedAt,
    super.providerNote,
    super.acceptedAt,
    super.closedAt,
  });

  factory AdoptionRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Adoption request document does not exist.');
    }

    final submittedAt = data['submittedAt'];
    final updatedAt = data['updatedAt'];

    if (submittedAt is! Timestamp) {
      throw StateError('Adoption request submittedAt is invalid.');
    }

    if (updatedAt is! Timestamp) {
      throw StateError('Adoption request updatedAt is invalid.');
    }

    return AdoptionRequestModel(
      requestId: document.id,
      listingId: data['listingId'] as String,
      requesterId: data['requesterId'] as String,
      providerId: data['providerId'] as String,
      message: data['message'] as String?,
      status: data['status'] as String,
      submittedAt: submittedAt.toDate(),
      updatedAt: updatedAt.toDate(),
      providerNote: data['providerNote'] as String?,
      acceptedAt: _timestampToDate(data['acceptedAt']),
      closedAt: _timestampToDate(data['closedAt']),
    );
  }

  static DateTime? _timestampToDate(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    throw StateError('Adoption request timestamp is invalid.');
  }
}
