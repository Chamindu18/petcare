import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';
import 'package:petcare/features/profile/presentation/pages/edit_profile_page.dart';

class _FakeProfileRepository implements ProfileRepository {
  bool updateCalled = false;
  String? updatedFullName;
  String? updatedPhone;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    return const Stream.empty();
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    updateCalled = true;
    updatedFullName = fullName;
    updatedPhone = phone;
  }

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {}
}

void main() {
  UserProfile createProfile() {
    return const UserProfile(
      uid: 'user-1',
      fullName: 'Test User',
      displayName: 'Test User',
      email: 'test@example.com',
      phone: '0712345678',
      role: 'owner',
      notificationEnabled: true,
    );
  }

  testWidgets('shows current profile information', (tester) async {
    final repository = _FakeProfileRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: EditProfilePage(
          profile: createProfile(),
          profileRepository: repository,
        ),
      ),
    );

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Update your name and contact details.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Test User'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '0712345678'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('validates required full name', (tester) async {
    final repository = _FakeProfileRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: EditProfilePage(
          profile: createProfile(),
          profileRepository: repository,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '');

    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(find.text('Full name is required.'), findsOneWidget);
    expect(repository.updateCalled, isFalse);
  });

  testWidgets('saves updated profile information', (tester) async {
    final repository = _FakeProfileRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: EditProfilePage(
          profile: createProfile(),
          profileRepository: repository,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Updated User');

    await tester.enterText(find.byType(TextFormField).last, '0771234567');

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.updateCalled, isTrue);
    expect(repository.updatedFullName, 'Updated User');
    expect(repository.updatedPhone, '0771234567');
  });
}
