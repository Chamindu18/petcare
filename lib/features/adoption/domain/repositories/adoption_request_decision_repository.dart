/// Mutation operations available to the adoption provider when reviewing
/// a request. Read/query operations remain in [AdoptionRequestRepository].
abstract interface class AdoptionRequestDecisionRepository {
  Future<void> acceptRequest({required String requestId, String? providerNote});

  Future<void> rejectRequest({required String requestId, String? providerNote});
}
