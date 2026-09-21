import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<List<Notification>> watchNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        FirebaseException(
          plugin: 'firebase_auth',
          code: 'unauthenticated',
          message: 'You must be signed in to view notifications.',
        ),
      );
    }

    return _firestore
        .collection('notifications')
        .where('recipientUserId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(NotificationModel.fromFirestore).toList(),
        );
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unauthenticated',
        message: 'You must be signed in to update notifications.',
      );
    }

    final notificationReference = _firestore
        .collection('notifications')
        .doc(notificationId);

    final notification = await notificationReference.get();

    if (!notification.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Notification could not be found.',
      );
    }

    final data = notification.data();

    if (data?['recipientUserId'] != user.uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You cannot update this notification.',
      );
    }

    await notificationReference.update({'read': true});
  }

  @override
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unauthenticated',
        message: 'You must be signed in to update notifications.',
      );
    }

    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientUserId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.update(document.reference, {'read': true});
    }

    await batch.commit();
  }
}
