import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';
import 'package:petcare/features/profile/presentation/pages/edit_profile_page.dart';

class _FakeProfileRepository implements ProfileRepository {
  bool updateCalled = false;
  int updateCalls = 0;

  String? updatedFullName;
  String? updatedPhone;

  Object? updateError;
  Completer<void>? updateCompleter;

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
    updateCalls++;

    updatedFullName = fullName;
    updatedPhone = phone;

    final completer = updateCompleter;
    if (completer != null) {
      await completer.future;
    }

    final error = updateError;
    if (error != null) {
      throw error;
    }
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

  Future<void> pumpEditProfile(
    WidgetTester tester,
    _FakeProfileRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditProfilePage(
          profile: createProfile(),
          profileRepository: repository,
        ),
      ),
    );
  }

  testWidgets('shows current profile information', (tester) async {
    final repository = _FakeProfileRepository();

    await pumpEditProfile(tester, repository);

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Update your name and contact details.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Test User'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '0712345678'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('validates required full name', (tester) async {
    final repository = _FakeProfileRepository();

    await pumpEditProfile(tester, repository);

    await tester.enterText(find.byType(TextFormField).first, '');

    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(find.text('Full name is required.'), findsOneWidget);
    expect(repository.updateCalled, isFalse);
  });

  testWidgets('rejects a full name containing only one character', (
    tester,
  ) async {
    final repository = _FakeProfileRepository();

    await pumpEditProfile(tester, repository);

    await tester.enterText(find.byType(TextFormField).first, 'A');

    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(
      find.text('Full name must contain at least 2 characters.'),
      findsOneWidget,
    );
    expect(repository.updateCalled, isFalse);
  });

  testWidgets('rejects numbers in the full name', (tester) async {
    final repository = _FakeProfileRepository();

    await pumpEditProfile(tester, repository);

    await tester.enterText(find.byType(TextFormField).first, 'User123');

    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(find.text('Full name cannot contain numbers.'), findsOneWidget);
    expect(repository.updateCalled, isFalse);
  });

  testWidgets('rejects an invalid phone number', (tester) async {
    final repository = _FakeProfileRepository();

    await pumpEditProfile(tester, repository);

    await tester.enterText(find.byType(TextFormField).last, '12345');

    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(
      find.text(
        'Enter a valid Sri Lankan number '
        '(e.g. 0771234567 or +94771234567).',
      ),
      findsOneWidget,
    );
    expect(repository.updateCalled, isFalse);
  });

  testWidgets('allows an empty optional phone number', (tester) async {
    final repository = _FakeProfileRepository();

    await pumpEditProfile(tester, repository);

    await tester.enterText(find.byType(TextFormField).last, '');

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.updateCalled, isTrue);
    expect(repository.updatedPhone, '');
  });

  final validPhoneNumbers = [
    '0771234567',
    '077-123-4567',
    '+94771234567',
    '+94 77 123 4567',
    '0112345678',
    '+94 11 234 5678',
  ];

  for (final phone in validPhoneNumbers) {
    testWidgets('accepts valid phone number: $phone', (tester) async {
      final repository = _FakeProfileRepository();

      await pumpEditProfile(tester, repository);

      await tester.enterText(find.byType(TextFormField).last, phone);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(repository.updateCalled, isTrue);
      expect(repository.updatedPhone, phone.replaceAll(RegExp(r'[\s()-]'), ''));
    });
  }

  testWidgets('normalizes name whitespace before saving', (tester) async {
    final repository = _FakeProfileRepository();

    await pumpEditProfile(tester, repository);

    await tester.enterText(
      find.byType(TextFormField).first,
      '  Updated    User  ',
    );

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.updateCalled, isTrue);
    expect(repository.updatedFullName, 'Updated User');
  });

  testWidgets('prevents duplicate submissions while saving', (tester) async {
    final repository = _FakeProfileRepository()
      ..updateCompleter = Completer<void>();

    await pumpEditProfile(tester, repository);

    await tester.enterText(find.byType(TextFormField).first, 'Updated User');

    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(repository.updateCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(button.onPressed, isNull);

    repository.updateCompleter!.complete();

    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
  });

  testWidgets('shows an error when the repository update fails', (
    tester,
  ) async {
    final repository = _FakeProfileRepository()
      ..updateError = StateError('Network failure');

    await pumpEditProfile(tester, repository);

    await tester.enterText(find.byType(TextFormField).first, 'Updated User');

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to update your profile. Please try again.'),
      findsOneWidget,
    );

    expect(find.text('Edit Profile'), findsOneWidget);
  });
}
