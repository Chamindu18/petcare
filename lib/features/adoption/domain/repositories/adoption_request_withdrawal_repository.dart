/// Mutation operation available to an owner for their own pending request.
abstract interface class AdoptionRequestWithdrawalRepository {
  Future<void> withdrawRequest({required String requestId});
}
