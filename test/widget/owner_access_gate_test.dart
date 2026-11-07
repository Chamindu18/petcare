
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/owner_access_gate.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.role);

  final String? role;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    return Stream<UserProfile?>.value(
      role == null
          ? null
          : UserProfile(
              uid: 'test-user',
              fullName: 'Test User',
              displayName: 'Test User',
              email: 'test@example.com',
              phone: '0712345678',
              role: role!,
              notificationEnabled: true,
            ),
    );
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {}

  @override
  Future<void> updateNotificationPreference({
    required bool enabled,
  }) async {}
}

void main() {
  group('OwnerAccessGate', () {
    testWidgets('allows an owner to see the protected screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerAccessGate(
            profileRepository: _FakeProfileRepository('owner'),
            childBuilder: (_) => const Text('owner-only-content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('owner-only-content'), findsOneWidget);
      expect(find.text('Owner access required'), findsNothing);
    });

    testWidgets('blocks an adoption provider from owner-only screens', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerAccessGate(
            profileRepository: _FakeProfileRepository(
              'adoption_provider',
            ),
            childBuilder: (_) => const Text('owner-only-content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Owner access required'), findsOneWidget);
      expect(find.text('owner-only-content'), findsNothing);
    });

    testWidgets('blocks an account with no profile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerAccessGate(
            profileRepository: _FakeProfileRepository(null),
            childBuilder: (_) => const Text('owner-only-content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Owner access required'), findsOneWidget);
      expect(find.text('owner-only-content'), findsNothing);
    });
  });
}
