import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';
import 'package:petcare/app/router/adoption_provider_access_gate.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  final UserProfile? profile;

  @override
  Stream<UserProfile?> watchCurrentProfile() => Stream.value(profile);

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {}

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {}
}

UserProfile _profile(String role) {
  return UserProfile(
    uid: 'user-1',
    fullName: 'Test User',
    displayName: 'Test User',
    email: 'test@example.com',
    phone: '',
    role: role,
    notificationEnabled: true,
  );
}

Widget _buildGate(String role) {
  return MaterialApp(
    home: AdoptionProviderAccessGate(
      profileRepository: _FakeProfileRepository(_profile(role)),
      childBuilder: (_) => const Scaffold(body: Text('Provider-only content')),
    ),
  );
}

void main() {
  testWidgets('allows an adoption provider to access provider content', (
    tester,
  ) async {
    await tester.pumpWidget(_buildGate('adoption_provider'));
    await tester.pumpAndSettle();

    expect(find.text('Provider-only content'), findsOneWidget);
    expect(find.text('Provider access required'), findsNothing);
  });

  testWidgets('denies an owner access to provider content', (tester) async {
    await tester.pumpWidget(_buildGate('owner'));
    await tester.pumpAndSettle();

    expect(find.text('Provider-only content'), findsNothing);
    expect(find.text('Provider access required'), findsOneWidget);
  });

  testWidgets('denies access when the role is unknown', (tester) async {
    await tester.pumpWidget(_buildGate('unknown_role'));
    await tester.pumpAndSettle();

    expect(find.text('Provider-only content'), findsNothing);
    expect(find.text('Provider access required'), findsOneWidget);
  });
}
