import '../entities/adoption_request.dart';

abstract interface class AdoptionRequestRepository {
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? message,
  });

  Stream<AdoptionRequest?> watchRequest({required String requestId});
}
