import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/notifications/data/models/notification_model.dart';

void main() {
  final data = {
    'recipientUserId': 'owner-1',
    'type': 'appointment_confirmed',
    'message': 'Confirmed',
    'read': true,
    'targetType': 'appointment',
    'targetId': 'appointment-1',
    'createdAt': Timestamp.fromDate(DateTime(2026, 11, 7)),
  };

  test('read stays false for a pending Firestore write', () {
    expect(
      NotificationModel.fromData('notice-1', data, hasPendingWrites: true).read,
      isFalse,
    );
  });

  test('read becomes true after Firestore confirms the write', () {
    expect(
      NotificationModel.fromData(
        'notice-1',
        data,
        hasPendingWrites: false,
      ).read,
      isTrue,
    );
  });
}
