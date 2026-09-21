import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.notificationId,
    required super.recipientUserId,
    required super.type,
    required super.message,
    required super.read,
    required super.targetType,
    required super.targetId,
    required super.createdAt,
  });

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Notification document does not exist.');
    }

    final createdAt = data['createdAt'];

    if (createdAt is! Timestamp) {
      throw StateError('Notification createdAt is invalid.');
    }

    return NotificationModel(
      notificationId: document.id,
      recipientUserId: data['recipientUserId'] as String,
      type: data['type'] as String,
      message: data['message'] as String,
      read: data['read'] as bool,
      targetType: data['targetType'] as String,
      targetId: data['targetId'] as String,
      createdAt: createdAt.toDate(),
    );
  }
}
