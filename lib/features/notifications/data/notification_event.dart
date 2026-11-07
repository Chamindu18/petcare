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
    String? notificationId,
    Map<String, Object?> details = const {},
  }) {
    transaction.set(
      firestore
          .collection('notifications')
          .doc(notificationId ?? '${type}_$targetId'),
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

  /// Resolves the public directory side of the veterinarian/Auth UID link.
  ///
  /// The matching private `users/{uid}` account is intentionally not readable
  /// by other clients. Firestore Rules perform that final role, hospital, and
  /// vetId verification when the notification is written.
  static Future<String?> resolveVeterinarianRecipient(
    Transaction transaction,
    FirebaseFirestore firestore, {
    required String veterinarianId,
    required String hospitalId,
  }) async {
    if (veterinarianId.isEmpty ||
        hospitalId.isEmpty ||
        hospitalId == 'unassigned') {
      return null;
    }

    final directory = await transaction.get(
      firestore.collection('veterinarians').doc(veterinarianId),
    );
    final data = directory.data();
    final recipientUserId = data?['userId'];

    if (data?['active'] != true ||
        data?['hospitalId'] != hospitalId ||
        (data!.containsKey('vetId') && data['vetId'] != veterinarianId) ||
        recipientUserId is! String ||
        recipientUserId.isEmpty ||
        recipientUserId.contains('/')) {
      return null;
    }

    return recipientUserId;
  }
}
