import '../entities/adoption_request.dart';

abstract interface class AdoptionRequestRepository {
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? recipientId,
    String recipientType = 'adoption_provider',
    String? message,
  });

  Stream<List<AdoptionRequest>> watchMyRequests();

  Stream<AdoptionRequest?> watchRequest({required String requestId});

  /// Requests addressed to the current listing owner (provider or owner).
  Stream<List<AdoptionRequest>> watchReceivedRequests();
}
