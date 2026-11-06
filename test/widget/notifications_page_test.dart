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

    testWidgets('shows event titles and verified details', (tester) async {
      final notifications = [
        notification_entity.Notification(
          notificationId: 'appointment-confirmed',
          recipientUserId: 'owner-1',
          type: 'appointment_confirmed',
          message: 'Your appointment was confirmed.',
          read: false,
          targetType: 'appointment',
          targetId: 'appointment-1',
          createdAt: DateTime(2026, 11, 6),
          appointmentTime: DateTime(2026, 11, 10, 14, 30),
        ),
        notification_entity.Notification(
          notificationId: 'queue-checked-in',
          recipientUserId: 'owner-1',
          type: 'queue_checked_in',
          message: 'Your pet was checked in to the queue.',
          read: true,
          targetType: 'queue',
          targetId: 'queue-1',
          createdAt: DateTime(2026, 11, 6),
          queueNumber: 4,
        ),
        notification_entity.Notification(
          notificationId: 'adoption-accepted',
          recipientUserId: 'owner-1',
          type: 'adoption_accepted',
          message: 'Your adoption request was accepted.',
          read: false,
          targetType: 'adoption_request',
          targetId: 'request-1',
          createdAt: DateTime(2026, 11, 6),
          listingName: 'Buddy',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: _FakeNotificationRepository(
              notifications: notifications,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Appointment confirmed'), findsOneWidget);
      expect(find.textContaining('Scheduled: 10/11/2026'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Queue number: 4'), 100);
      expect(find.text('Queue number: 4'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Listing: Buddy'), 100);
      expect(find.text('Listing: Buddy'), findsOneWidget);
    });
  });
}
