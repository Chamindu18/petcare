import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/notifications/domain/entities/notification.dart'
    as notification_entity;
import 'package:petcare/features/notifications/domain/repositories/notification_repository.dart';
import 'package:petcare/features/notifications/presentation/pages/notifications_page.dart';

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Stream<List<notification_entity.Notification>> watchNotifications() {
    return Stream.value(const []);
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
  }) async {}

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
  });
}