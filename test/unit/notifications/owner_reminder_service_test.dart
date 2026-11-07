import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/notifications/data/owner_reminder_service.dart';
import 'package:timezone/timezone.dart' as tz;

class _FakeNotifications implements LocalReminderNotifications {
  _FakeNotifications({this.allowPermission = true});
  final bool allowPermission;
  final Map<int, PendingNotificationRequest> pending = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => allowPermission;

  @override
  Future<List<PendingNotificationRequest>> pendingRequests() async =>
      pending.values.toList();

  @override
  Future<void> cancel(int id) async {
    pending.remove(id);
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
  }) async {
    pending[id] = PendingNotificationRequest(id, title, body, payload);
  }
}

Future<void> _until(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Reminder state did not settle.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('appointment and vaccination reminders reschedule and cancel', () async {
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'owner-1'));
    final firestore = FakeFirebaseFirestore();
    final notifications = _FakeNotifications();
    final appointmentTime = DateTime.now().add(const Duration(days: 3));
    final due = DateTime.now().add(const Duration(days: 4));
    await firestore.collection('users').doc('owner-1').set({
      'role': 'owner',
      'notificationEnabled': true,
    });
    await firestore.collection('pets').doc('pet-1').set({
      'ownerId': 'owner-1',
      'name': 'Milo',
    });
    await firestore.collection('appointments').doc('appointment-1').set({
      'ownerId': 'owner-1',
      'status': 'confirmed',
      'dateTime': appointmentTime.toUtc().toIso8601String(),
    });
    await firestore.collection('vaccinations').doc('vaccination-1').set({
      'petId': 'pet-1',
      'name': 'Rabies',
      'nextDueDate': due.toIso8601String(),
    });
    final service = OwnerReminderService(
      auth: auth,
      firestore: firestore,
      notifications: notifications,
      timezoneName: () async => 'Asia/Colombo',
    );
    await service.start();
    await auth.signInWithCredential(null);
    await _until(() => notifications.pending.length == 2);
    expect(
      notifications.pending.values.map((value) => value.payload),
      containsAll([
        'petcare-owner:owner-1:appointment:appointment-1',
        'petcare-owner:owner-1:vaccination:vaccination-1',
      ]),
    );

    await firestore.collection('appointments').doc('appointment-1').update({
      'status': 'cancelled',
    });
    await _until(() => notifications.pending.length == 1);
    expect(
      notifications.pending.values.single.payload,
      contains('vaccination'),
    );
    await firestore.collection('vaccinations').doc('vaccination-1').delete();
    await _until(() => notifications.pending.isEmpty);
    service.dispose();
  });

  test(
    'logout and account switch clear prior reminders; denial schedules none',
    () async {
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'owner-1'));
      final firestore = FakeFirebaseFirestore();
      final notifications = _FakeNotifications();
      await firestore.collection('users').doc('owner-1').set({
        'role': 'owner',
        'notificationEnabled': true,
      });
      await firestore.collection('appointments').doc('appointment-1').set({
        'ownerId': 'owner-1',
        'status': 'confirmed',
        'dateTime': DateTime.now()
            .add(const Duration(days: 3))
            .toUtc()
            .toIso8601String(),
      });
      final service = OwnerReminderService(
        auth: auth,
        firestore: firestore,
        notifications: notifications,
        timezoneName: () async => 'Asia/Colombo',
      );
      await service.start();
      await auth.signInWithCredential(null);
      await _until(() => notifications.pending.length == 1);
      await auth.signOut();
      await _until(() => notifications.pending.isEmpty);
      await firestore.collection('users').doc('owner-2').set({
        'role': 'owner',
        'notificationEnabled': true,
      });
      await firestore.collection('appointments').doc('appointment-2').set({
        'ownerId': 'owner-2',
        'status': 'confirmed',
        'dateTime': DateTime.now()
            .add(const Duration(days: 4))
            .toUtc()
            .toIso8601String(),
      });
      auth.mockUser = MockUser(uid: 'owner-2');
      await auth.signInWithCredential(null);
      await _until(() => notifications.pending.length == 1);
      expect(
        notifications.pending.values.single.payload,
        'petcare-owner:owner-2:appointment:appointment-2',
      );
      await auth.signOut();
      await _until(() => notifications.pending.isEmpty);
      service.dispose();

      auth.mockUser = MockUser(uid: 'owner-1');
      final deniedNotifications = _FakeNotifications(allowPermission: false);
      final denied = OwnerReminderService(
        auth: auth,
        firestore: firestore,
        notifications: deniedNotifications,
        timezoneName: () async => 'Asia/Colombo',
      );
      await denied.start();
      await auth.signInWithCredential(null);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(deniedNotifications.pending, isEmpty);
      denied.dispose();
    },
  );
}
