/// Mutation operations for the authorized owner of a listing to review a request.
/// The repository and Firestore rules verify the listing ownership and role.
abstract interface class AdoptionRequestDecisionRepository {
  Future<void> acceptRequest({required String requestId, String? providerNote});

  Future<void> rejectRequest({required String requestId, String? providerNote});
}
