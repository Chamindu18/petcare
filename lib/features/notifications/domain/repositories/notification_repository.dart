import '../entities/notification.dart';

abstract interface class NotificationRepository {
  Stream<List<Notification>> watchNotifications();

  Future<void> markAsRead({required String notificationId});

  Future<void> markAllAsRead();
}
