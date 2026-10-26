class AdoptionRequest {
  const AdoptionRequest({
    required this.requestId,
    required this.listingId,
    required this.requesterId,
    required this.providerId,
    this.recipientId,
    this.recipientType = 'adoption_provider',
    this.message,
    required this.status,
    required this.submittedAt,
    required this.updatedAt,
    this.providerNote,
    this.acceptedAt,
    this.closedAt,
  });

  final String requestId;
  final String listingId;
  final String requesterId;

  /// Legacy alias retained for older provider request documents.
  final String providerId;
  final String? recipientId;
  final String recipientType;

  String get effectiveRecipientId => recipientId ?? providerId;

  final String? message;
  final String status;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final String? providerNote;
  final DateTime? acceptedAt;
  final DateTime? closedAt;
}
