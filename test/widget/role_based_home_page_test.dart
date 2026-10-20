import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/role_based_home_page.dart';
import 'package:petcare/features/home/presentation/pages/owner_shell_page.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this._watchProfile);

  final Stream<UserProfile?> Function(int callNumber) _watchProfile;

  int watchCount = 0;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    watchCount++;
    return _watchProfile(watchCount);
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {}

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {}
}

UserProfile _profileWithRole(String role) {
  return UserProfile(
    uid: 'test-user',
    fullName: 'Test User',
    displayName: 'Test User',
    email: 'test@example.com',
    phone: '0712345678',
    role: role,
    notificationEnabled: true,
  );
}

Widget _testDashboard(String label) {
  return Scaffold(body: Center(child: Text(label)));
}

void main() {
  group('RoleBasedHomePage', () {
    testWidgets('routes an owner to the owner dashboard destination', (
      tester,
    ) async {
      final repository = _FakeProfileRepository(
        (_) => Stream<UserProfile?>.value(_profileWithRole('owner')),
      );

      var ownerBuilderCalled = false;
      var providerBuilderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: RoleBasedHomePage(
            profileRepository: repository,
            ownerDashboardBuilder: () {
              ownerBuilderCalled = true;
              return _testDashboard('owner-dashboard-destination');
            },
            adoptionProviderDashboardBuilder: () {
              providerBuilderCalled = true;
              return _testDashboard('provider-dashboard-destination');
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('owner-dashboard-destination'), findsOneWidget);
      expect(ownerBuilderCalled, isTrue);
      expect(providerBuilderCalled, isFalse);
    });

    testWidgets(
      'routes an adoption provider to the provider dashboard destination',
      (tester) async {
        final repository = _FakeProfileRepository(
          (_) =>
              Stream<UserProfile?>.value(_profileWithRole('adoption_provider')),
        );

        var ownerBuilderCalled = false;
        var providerBuilderCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: RoleBasedHomePage(
              profileRepository: repository,
              ownerDashboardBuilder: () {
                ownerBuilderCalled = true;
                return _testDashboard('owner-dashboard-destination');
              },
              adoptionProviderDashboardBuilder: () {
                providerBuilderCalled = true;
                return _testDashboard('provider-dashboard-destination');
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('provider-dashboard-destination'), findsOneWidget);
        expect(providerBuilderCalled, isTrue);
        expect(ownerBuilderCalled, isFalse);
      },
    );

    testWidgets(
      'does not grant role-specific access when the profile is missing',
      (tester) async {
        final repository = _FakeProfileRepository(
          (_) => Stream<UserProfile?>.value(null),
        );

        await tester.pumpWidget(
          MaterialApp(home: RoleBasedHomePage(profileRepository: repository)),
        );

        await tester.pumpAndSettle();

        expect(find.text('Account role unavailable'), findsOneWidget);
        expect(
          find.textContaining(
            'Access to role-specific features has not been granted.',
          ),
          findsOneWidget,
        );
        expect(find.byType(OwnerShellPage), findsNothing);
      },
    );

    testWidgets('does not grant role-specific access for an unknown role', (
      tester,
    ) async {
      final repository = _FakeProfileRepository(
        (_) => Stream<UserProfile?>.value(_profileWithRole('admin')),
      );

      await tester.pumpWidget(
        MaterialApp(home: RoleBasedHomePage(profileRepository: repository)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Account role unavailable'), findsOneWidget);
      expect(find.byType(OwnerShellPage), findsNothing);
      expect(find.text('Dashboard unavailable'), findsNothing);
    });

    testWidgets('shows a retry option when profile loading fails and retries', (
      tester,
    ) async {
      final repository = _FakeProfileRepository((callNumber) {
        if (callNumber == 1) {
          return Stream<UserProfile?>.error(
            StateError('Simulated profile loading failure'),
          );
        }

        return Stream<UserProfile?>.value(null);
      });

      await tester.pumpWidget(
        MaterialApp(home: RoleBasedHomePage(profileRepository: repository)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load profile'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(repository.watchCount, 1);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Account role unavailable'), findsOneWidget);
      expect(find.byType(OwnerShellPage), findsNothing);
      expect(repository.watchCount, 2);
    });
  });
}
