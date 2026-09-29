import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';
import 'package:petcare/features/profile/presentation/pages/notification_settings_page.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  UserProfile? profile;
  bool? lastNotificationPreference;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    return Stream.value(profile);
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {}

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {
    lastNotificationPreference = enabled;

    profile = UserProfile(
      uid: profile!.uid,
      fullName: profile!.fullName,
      displayName: profile!.displayName,
      email: profile!.email,
      phone: profile!.phone,
      role: profile!.role,
      notificationEnabled: enabled,
    );
  }
}

UserProfile _createProfile({bool notificationEnabled = true}) {
  return UserProfile(
    uid: 'user-1',
    fullName: 'Amandi Rajapaksha',
    displayName: 'Amandi Rajapaksha',
    email: 'amandi@example.com',
    phone: '0771234567',
    role: 'owner',
    notificationEnabled: notificationEnabled,
  );
}

void main() {
  testWidgets('shows current notification preference', (tester) async {
    final repository = _FakeProfileRepository(
      _createProfile(notificationEnabled: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsPage(
          profile: repository.profile!,
          profileRepository: repository,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Notification Settings'), findsOneWidget);
    expect(find.text('Allow Notifications'), findsOneWidget);
    expect(find.text('Notifications are enabled.'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isTrue);
  });

  testWidgets('updates notification preference when toggled', (tester) async {
    final repository = _FakeProfileRepository(
      _createProfile(notificationEnabled: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsPage(
          profile: repository.profile!,
          profileRepository: repository,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repository.lastNotificationPreference, isFalse);
    expect(
      find.text('Notification settings updated successfully.'),
      findsOneWidget,
    );
  });

  testWidgets('shows disabled state when notifications are off', (
    tester,
  ) async {
    final repository = _FakeProfileRepository(
      _createProfile(notificationEnabled: false),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsPage(
          profile: repository.profile!,
          profileRepository: repository,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Notifications are disabled.'), findsOneWidget);

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, isFalse);
  });
}
