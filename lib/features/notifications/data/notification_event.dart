import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical content is also checked by Firestore Rules. Event writes must be
/// in the same transaction as their source status change.
class NotificationEvent {
  static void create(
    Transaction transaction,
    FirebaseFirestore firestore, {
    required String recipientId,
    required String type,
    required String message,
    required String targetType,
    required String targetId,
    Map<String, Object?> details = const {},
  }) {
    transaction.set(
      firestore.collection('notifications').doc('${type}_$targetId'),
      {
        ...details,
        'recipientUserId': recipientId,
        'type': type,
        'message': message,
        'read': false,
        'targetType': targetType,
        'targetId': targetId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
