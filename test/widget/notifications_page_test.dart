import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/notifications/domain/entities/notification.dart'
    as notification_entity;
import 'package:petcare/features/notifications/domain/repositories/notification_repository.dart';
import 'package:petcare/features/notifications/presentation/pages/notifications_page.dart';

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({this.notifications = const []});

  final List<notification_entity.Notification> notifications;

  @override
  Stream<List<notification_entity.Notification>> watchNotifications() {
    return Stream.value(notifications);
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {}

  @override
  Future<void> markAllAsRead() async {}
}

void main() {
  group('NotificationsPage', () {
    testWidgets('shows empty state when there are no notifications', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: _FakeNotificationRepository(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(
        find.text('You’re all caught up. New updates will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('shows an unread notification', (tester) async {
      final notification = notification_entity.Notification(
        notificationId: 'notification-1',
        recipientUserId: 'user-1',
        type: 'adoption_request',
        message: 'You have received a new adoption request.',
        read: false,
        targetType: 'adoption_request',
        targetId: 'request-1',
        createdAt: DateTime(2026, 9, 20, 10, 30),
      );

      final repository = _FakeNotificationRepository(
        notifications: [notification],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(notificationRepository: repository),
        ),
      );

      await tester.pump();

      expect(
        find.text('You have received a new adoption request.'),
        findsOneWidget,
      );
      expect(find.text('Mark all read'), findsOneWidget);
    });
  });
}
