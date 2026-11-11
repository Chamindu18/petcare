import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/app/router/protected_session_gate.dart';
import 'package:petcare/app/router/role_based_home_page.dart';
import 'package:petcare/features/hospital_staff/domain/entities/hospital_staff_assignment.dart';
import 'package:petcare/features/hospital_staff/domain/repositories/hospital_staff_assignment_repository.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';

class _TestUser extends Fake implements User {
  _TestUser(this._uid);
  final String _uid;
  @override
  String get uid => _uid;
}

class _TestAuth extends Fake implements FirebaseAuth {
  _TestAuth(String uid) : _user = _TestUser(uid);

  final _changes = StreamController<User?>.broadcast(sync: true);
  User? _user;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> authStateChanges() => _changes.stream;

  void changeTo(String? uid) {
    _user = uid == null ? null : _TestUser(uid);
    _changes.add(_user);
  }

  Future<void> dispose() => _changes.close();
}

class _TestProfiles implements ProfileRepository {
  _TestProfiles(this.auth);
  final _TestAuth auth;
  final streams = <String, StreamController<UserProfile?>>{};

  @override
  Stream<UserProfile?> watchCurrentProfile() => streams
      .putIfAbsent(
        auth.currentUser!.uid,
        () => StreamController<UserProfile?>.broadcast(sync: true),
      )
      .stream;

  void emit(String uid, String role) {
    streams[uid]!.add(
      UserProfile(
        uid: uid,
        fullName: uid,
        displayName: uid,
        email: '',
        phone: '',
        role: role,
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
  Future<void> updateNotificationPreference({required bool enabled}) async {}

  Future<void> dispose() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

class _TestAssignments implements HospitalStaffAssignmentRepository {
  final changes = StreamController<HospitalStaffAssignment?>.broadcast(
    sync: true,
  );

  @override
  Stream<HospitalStaffAssignment?> watchCurrentAssignment() => changes.stream;

  Future<void> dispose() => changes.close();
}

Widget _workspace(String label) => Scaffold(body: Text(label));

void main() {
  late _TestAuth auth;
  late _TestProfiles profiles;
  late _TestAssignments assignments;

  setUp(() {
    auth = _TestAuth('A');
    profiles = _TestProfiles(auth);
    assignments = _TestAssignments();
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await assignments.dispose();
  });

  Future<void> pumpProtectedHome(WidgetTester tester) async {
    Widget roleHome() => RoleBasedHomePage(
      auth: auth,
      profileRepository: profiles,
      hospitalStaffAssignmentRepository: assignments,
      ownerDashboardBuilder: () => _workspace('${auth.currentUser?.uid} owner'),
      staffWorkspaceBuilder: (_, assignment) =>
          _workspace('${assignment.userId} staff'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProtectedSessionGate(
          auth: auth,
          sessionUid: 'A',
          childBuilder: (_) => roleHome(),
        ),
        routes: {
          AppRouter.login: (_) => _workspace('login'),
          AppRouter.home: (_) => roleHome(),
        },
      ),
    );
    profiles.emit('A', 'owner');
    await tester.pumpAndSettle();
    expect(find.text('A owner'), findsOneWidget);
  }

  testWidgets(
    'A to null removes the protected workspace and clears the stack',
    (tester) async {
      await pumpProtectedHome(tester);
      auth.changeTo(null);
      await tester.pumpAndSettle();
      expect(find.text('A owner'), findsNothing);
      expect(find.text('login'), findsOneWidget);
      expect(find.byType(RoleBasedHomePage), findsNothing);
    },
  );

  testWidgets('A to B waits for B profile and ignores a delayed A response', (
    tester,
  ) async {
    await pumpProtectedHome(tester);
    auth.changeTo('B');
    profiles.emit('A', 'owner');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('A owner'), findsNothing);
    expect(find.text('B owner'), findsNothing);

    profiles.emit('B', 'owner');
    await tester.pumpAndSettle();
    expect(find.text('B owner'), findsOneWidget);
    expect(find.text('A owner'), findsNothing);
  });

  testWidgets('rapid sign-out and B sign-in never restores A content', (
    tester,
  ) async {
    await pumpProtectedHome(tester);
    auth.changeTo(null);
    auth.changeTo('B');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('A owner'), findsNothing);
    expect(find.text('login'), findsNothing);

    profiles.emit('B', 'owner');
    await tester.pumpAndSettle();
    expect(find.text('B owner'), findsOneWidget);
  });

  testWidgets('B staff route waits for both B profile and active assignment', (
    tester,
  ) async {
    await pumpProtectedHome(tester);
    auth.changeTo('B');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('A owner'), findsNothing);
    expect(find.text('B staff'), findsNothing);

    profiles.emit('B', 'veterinary_staff');
    await tester.pump();
    expect(find.text('B staff'), findsNothing);

    assignments.changes.add(
      const HospitalStaffAssignment(
        userId: 'B',
        hospitalId: 'hospital-B',
        active: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('B staff'), findsNothing);

    assignments.changes.add(
      const HospitalStaffAssignment(
        userId: 'B',
        hospitalId: 'hospital-B',
        active: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('B staff'), findsOneWidget);
  });
}
