class Notification {
  const Notification({
    required this.notificationId,
    required this.recipientUserId,
    required this.type,
    required this.message,
    required this.read,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.appointmentTime,
    this.queueNumber,
    this.listingName,
  });

  final String notificationId;
  final String recipientUserId;
  final String type;
  final String message;
  final bool read;
  final String targetType;
  final String targetId;
  final DateTime createdAt;
  final DateTime? appointmentTime;
  final int? queueNumber;
  final String? listingName;
}
