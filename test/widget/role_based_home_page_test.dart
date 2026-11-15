import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/role_based_home_page.dart';
import 'package:petcare/features/auth/presentation/pages/complete_google_profile_page.dart';
import 'package:petcare/features/home/presentation/pages/owner_shell_page.dart';
import 'package:petcare/features/hospital_staff/domain/entities/hospital_staff_assignment.dart';
import 'package:petcare/features/hospital_staff/domain/repositories/hospital_staff_assignment_repository.dart';
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

class _GoogleUser extends Fake implements User {
  @override
  String? get displayName => null;

  @override
  List<UserInfo> get providerData => [_GoogleProviderInfo()];
}

class _GoogleProviderInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'google.com';
}

class _GoogleAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _GoogleUser();
}

class _FakeHospitalStaffAssignmentRepository
    implements HospitalStaffAssignmentRepository {
  _FakeHospitalStaffAssignmentRepository(this._watchAssignment);

  final Stream<HospitalStaffAssignment?> Function(int callNumber)
  _watchAssignment;

  int watchCount = 0;

  @override
  Stream<HospitalStaffAssignment?> watchCurrentAssignment() {
    watchCount++;
    return _watchAssignment(watchCount);
  }
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

HospitalStaffAssignment _staffAssignment({
  String userId = 'test-user',
  String hospitalId = 'hospital-001',
  bool active = true,
}) {
  return HospitalStaffAssignment(
    userId: userId,
    hospitalId: hospitalId,
    active: active,
  );
}

Widget _testDashboard(String label) {
  return Scaffold(body: Center(child: Text(label)));
}

void main() {
  group('RoleBasedHomePage', () {
    testWidgets('missing Google profile requires a name and retries creation', (
      tester,
    ) async {
      UserProfile? currentProfile;
      final repository = _FakeProfileRepository(
        (_) => Stream<UserProfile?>.value(currentProfile),
      );
      var attempts = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: RoleBasedHomePage(
            auth: _GoogleAuth(),
            profileRepository: repository,
            completeGoogleProfile: (name) async {
              attempts++;
              if (attempts == 1) throw StateError('temporary failure');
              expect(name, 'Actual Owner');
              currentProfile = _profileWithRole('owner');
            },
            ownerDashboardBuilder: () => _testDashboard('owner dashboard'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CompleteGoogleProfilePage), findsOneWidget);
      expect(find.text('owner dashboard'), findsNothing);

      await tester.tap(find.text('Save profile'));
      await tester.pump();
      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(attempts, 0);

      await tester.enterText(find.byType(TextFormField), '  Actual Owner  ');
      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to save your profile. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('owner dashboard'), findsNothing);

      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('owner dashboard'), findsOneWidget);
    });

    testWidgets('rebuilds the destination when the account UID changes', (
      tester,
    ) async {
      final profiles = StreamController<UserProfile?>();
      addTearDown(profiles.close);
      final repository = _FakeProfileRepository((_) => profiles.stream);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: RoleBasedHomePage(
            profileRepository: repository,
            ownerDashboardBuilder: () => _testDashboard('account ${++builds}'),
          ),
        ),
      );
      profiles.add(_profileWithRole('owner'));
      await tester.pumpAndSettle();
      expect(find.text('account 1'), findsOneWidget);

      profiles.add(
        UserProfile(
          uid: 'second-user',
          fullName: 'Second User',
          displayName: 'Second User',
          email: 'second@example.com',
          phone: '0712345678',
          role: 'owner',
          notificationEnabled: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('account 2'), findsOneWidget);
    });

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

    testWidgets('allows staff access when the hospital assignment is active', (
      tester,
    ) async {
      final profileRepository = _FakeProfileRepository(
        (_) => Stream<UserProfile?>.value(_profileWithRole('veterinary_staff')),
      );

      final assignmentRepository = _FakeHospitalStaffAssignmentRepository(
        (_) => Stream<HospitalStaffAssignment?>.value(_staffAssignment()),
      );

      HospitalStaffAssignment? receivedAssignment;

      await tester.pumpWidget(
        MaterialApp(
          home: RoleBasedHomePage(
            profileRepository: profileRepository,
            hospitalStaffAssignmentRepository: assignmentRepository,
            staffWorkspaceBuilder: (context, assignment) {
              receivedAssignment = assignment;

              return _testDashboard('staff-dashboard-${assignment.hospitalId}');
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('staff-dashboard-hospital-001'), findsOneWidget);
      expect(receivedAssignment, isNotNull);
      expect(receivedAssignment!.userId, 'test-user');
      expect(receivedAssignment!.hospitalId, 'hospital-001');
      expect(receivedAssignment!.active, isTrue);
      expect(assignmentRepository.watchCount, 1);
    });

    testWidgets('denies staff access when the hospital assignment is missing', (
      tester,
    ) async {
      final profileRepository = _FakeProfileRepository(
        (_) => Stream<UserProfile?>.value(_profileWithRole('veterinary_staff')),
      );

      final assignmentRepository = _FakeHospitalStaffAssignmentRepository(
        (_) => Stream<HospitalStaffAssignment?>.value(null),
      );

      var workspaceBuilderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: RoleBasedHomePage(
            profileRepository: profileRepository,
            hospitalStaffAssignmentRepository: assignmentRepository,
            staffWorkspaceBuilder: (context, assignment) {
              workspaceBuilderCalled = true;
              return _testDashboard('staff-dashboard');
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hospital access unavailable'), findsOneWidget);
      expect(find.text('staff-dashboard'), findsNothing);
      expect(workspaceBuilderCalled, isFalse);
    });

    testWidgets(
      'denies staff access when the hospital assignment is inactive',
      (tester) async {
        final profileRepository = _FakeProfileRepository(
          (_) =>
              Stream<UserProfile?>.value(_profileWithRole('veterinary_staff')),
        );

        final assignmentRepository = _FakeHospitalStaffAssignmentRepository(
          (_) => Stream<HospitalStaffAssignment?>.value(
            _staffAssignment(active: false),
          ),
        );

        var workspaceBuilderCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: RoleBasedHomePage(
              profileRepository: profileRepository,
              hospitalStaffAssignmentRepository: assignmentRepository,
              staffWorkspaceBuilder: (context, assignment) {
                workspaceBuilderCalled = true;
                return _testDashboard('staff-dashboard');
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Hospital access unavailable'), findsOneWidget);
        expect(find.text('staff-dashboard'), findsNothing);
        expect(workspaceBuilderCalled, isFalse);
      },
    );

    testWidgets(
      'denies staff access when the assignment stream returns an error',
      (tester) async {
        final profileRepository = _FakeProfileRepository(
          (_) =>
              Stream<UserProfile?>.value(_profileWithRole('veterinary_staff')),
        );

        final assignmentRepository = _FakeHospitalStaffAssignmentRepository(
          (_) => Stream<HospitalStaffAssignment?>.error(
            StateError('Simulated Firestore failure'),
          ),
        );

        var workspaceBuilderCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: RoleBasedHomePage(
              profileRepository: profileRepository,
              hospitalStaffAssignmentRepository: assignmentRepository,
              staffWorkspaceBuilder: (context, assignment) {
                workspaceBuilderCalled = true;
                return _testDashboard('staff-dashboard');
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Unable to verify hospital access'), findsOneWidget);
        expect(find.text('staff-dashboard'), findsNothing);
        expect(workspaceBuilderCalled, isFalse);
      },
    );
  });
}
