import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/notifications/domain/entities/notification.dart'
    as notification_entity;
import 'package:petcare/features/notifications/domain/repositories/notification_repository.dart';
import 'package:petcare/features/notifications/presentation/pages/notifications_page.dart';

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({
    this.notifications = const [],
    this.notificationsStream,
    this.onMarkAsRead,
  });

  final List<notification_entity.Notification> notifications;
  final Stream<List<notification_entity.Notification>>? notificationsStream;
  final Future<void> Function(String)? onMarkAsRead;
  int readUpdateCount = 0;

  @override
  Stream<List<notification_entity.Notification>> watchNotifications() {
    return notificationsStream ?? Stream.value(notifications);
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    readUpdateCount++;
    await onMarkAsRead?.call(notificationId);
  }

  @override
  Future<void> markAllAsRead() async {}
}

notification_entity.Notification _notification({
  String id = 'notice-1',
  String targetType = 'appointment',
  String targetId = 'appointment-1',
  bool read = false,
}) => notification_entity.Notification(
  notificationId: id,
  recipientUserId: 'owner-1',
  type: 'appointment_confirmed',
  message: 'Your appointment was confirmed.',
  read: read,
  targetType: targetType,
  targetId: targetId,
  createdAt: DateTime(2026, 11, 7),
);

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

    testWidgets('successful read update opens the appointment', (tester) async {
      final repository = _FakeNotificationRepository(
        notifications: [_notification()],
      );
      String? openedId;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: repository,
            onOpenAppointmentById: (id) => openedId = id,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Appointment confirmed'));
      await tester.pump();
      expect(repository.readUpdateCount, 1);
      expect(openedId, 'appointment-1');
      expect(find.textContaining('Unable to mark'), findsNothing);
    });

    testWidgets('failed read update keeps inbox and opens destination', (
      tester,
    ) async {
      final repository = _FakeNotificationRepository(
        notifications: [_notification()],
        onMarkAsRead: (_) async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      );
      String? openedId;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: repository,
            onOpenAppointmentById: (id) => openedId = id,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Appointment confirmed'));
      await tester.pump();
      expect(openedId, 'appointment-1');
      expect(
        find.text('Unable to mark notification as read. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Unable to load notifications'), findsNothing);
      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.text('Your appointment was confirmed.'), findsOneWidget);
    });

    testWidgets('repeated taps while read update is pending run once', (
      tester,
    ) async {
      final pending = Completer<void>();
      final repository = _FakeNotificationRepository(
        notifications: [_notification()],
        onMarkAsRead: (_) => pending.future,
      );
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: repository,
            onOpenAppointment: () => opens++,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Appointment confirmed'));
      await tester.tap(find.text('Appointment confirmed'));
      await tester.pump();
      expect(repository.readUpdateCount, 1);
      expect(opens, 0);
      expect(find.text('Mark all read'), findsOneWidget);
      pending.complete();
      await tester.pump();
      expect(opens, 1);
    });

    testWidgets('missing and unknown destinations do not navigate', (
      tester,
    ) async {
      final repository = _FakeNotificationRepository(
        notifications: [
          _notification(id: 'missing', targetId: ''),
          _notification(id: 'unknown', targetType: 'unknown'),
        ],
      );
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: repository,
            onOpenAppointment: () => opens++,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Your appointment was confirmed.').first);
      await tester.pump();
      await tester.tap(find.text('Your appointment was confirmed.').last);
      await tester.pump();
      expect(opens, 0);
      expect(repository.readUpdateCount, 2);
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('denied notification stream shows no notification content', (
      tester,
    ) async {
      final repository = _FakeNotificationRepository(
        notificationsStream: Stream.error(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(notificationRepository: repository),
        ),
      );
      await tester.pump();
      expect(find.text('Unable to load notifications'), findsOneWidget);
      expect(find.text('Your appointment was confirmed.'), findsNothing);
    });

    testWidgets('disposing page during update causes no late navigation', (
      tester,
    ) async {
      final pending = Completer<void>();
      final repository = _FakeNotificationRepository(
        notifications: [_notification()],
        onMarkAsRead: (_) => pending.future,
      );
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            notificationRepository: repository,
            onOpenAppointment: () => opens++,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Appointment confirmed'));
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      pending.completeError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await tester.pump();
      expect(opens, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
