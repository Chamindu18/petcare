import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/router/app_router.dart';
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
    testWidgets('staff queue notification opens the queue callback', (
      tester,
    ) async {
      var openedQueue = false;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: _FakeNotificationRepository(
              notifications: [
                notification_entity.Notification(
                  notificationId: 'queue-event',
                  recipientUserId: 'staff-a',
                  type: 'queue_called',
                  message: 'A patient was called.',
                  read: false,
                  targetType: 'queue',
                  targetId: 'queue-1',
                  createdAt: DateTime(2026, 11, 7),
                ),
              ],
            ),
            onOpenQueue: () => openedQueue = true,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Called to consultation'));
      await tester.pump();
      expect(openedQueue, isTrue);
    });

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

    testWidgets('provider request notification opens request management', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.adoptionRequests: (_) =>
                const Scaffold(body: Text('Provider request management')),
          },
          home: NotificationsPage(
            notificationRepository: _FakeNotificationRepository(
              notifications: [
                notification_entity.Notification(
                  notificationId:
                      'adoption_request_submitted_listing-1_owner-1',
                  recipientUserId: 'provider-1',
                  type: 'adoption_request_submitted',
                  message: 'You received a new adoption application for Buddy.',
                  read: false,
                  targetType: 'adoption_request',
                  targetId: 'request-1',
                  createdAt: DateTime(2026, 11, 7),
                  listingName: 'Buddy',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('New adoption request'), findsOneWidget);
      expect(find.text('Listing: Buddy'), findsOneWidget);
      await tester.tap(find.text('New adoption request'));
      await tester.pumpAndSettle();

      expect(find.text('Provider request management'), findsOneWidget);
    });

    testWidgets('staff request opens the staff appointment callback', (
      tester,
    ) async {
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: _FakeNotificationRepository(
              notifications: [
                notification_entity.Notification(
                  notificationId: 'appointment_requested_appointment-1_staff-a',
                  recipientUserId: 'staff-a',
                  type: 'appointment_requested',
                  message: 'A new appointment request needs review.',
                  read: false,
                  targetType: 'appointment',
                  targetId: 'appointment-1',
                  createdAt: DateTime(2026, 11, 7),
                  appointmentTime: DateTime(2026, 11, 10, 14, 30),
                ),
              ],
            ),
            onOpenAppointment: () => opened = true,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('New appointment request'), findsOneWidget);
      expect(find.textContaining('Scheduled: 10/11/2026'), findsOneWidget);
      await tester.tap(find.text('New appointment request'));
      await tester.pump();
      expect(opened, isTrue);
    });

    testWidgets(
      'veterinarian events use the appointment ID and removed events do not link',
      (tester) async {
        String? openedId;
        await tester.pumpWidget(
          MaterialApp(
            home: NotificationsPage(
              notificationRepository: _FakeNotificationRepository(
                notifications: [
                  notification_entity.Notification(
                    notificationId: 'patient_checked_in_appointment-1',
                    recipientUserId: 'doctor-1',
                    type: 'patient_checked_in',
                    message: 'An assigned patient has checked in.',
                    read: false,
                    targetType: 'appointment',
                    targetId: 'appointment-1',
                    createdAt: DateTime(2026, 11, 7),
                    queueNumber: 3,
                  ),
                  notification_entity.Notification(
                    notificationId:
                        'appointment_unassigned_appointment-2_doctor-1',
                    recipientUserId: 'doctor-1',
                    type: 'appointment_unassigned',
                    message: 'An appointment was removed from your schedule.',
                    read: false,
                    targetType: 'none',
                    targetId: 'appointment-2',
                    createdAt: DateTime(2026, 11, 7),
                  ),
                ],
              ),
              onOpenAppointmentById: (id) => openedId = id,
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Patient checked in'), findsOneWidget);
        expect(find.text('Appointment removed'), findsOneWidget);
        await tester.tap(find.text('Patient checked in'));
        await tester.pump();
        expect(openedId, 'appointment-1');
        openedId = null;
        await tester.tap(find.text('Appointment removed'));
        await tester.pump();
        expect(openedId, isNull);
      },
    );
  });
}
