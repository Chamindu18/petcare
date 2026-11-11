import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/app/router/protected_session_gate.dart';
import 'package:petcare/app/router/qr_scanner_access_gate.dart';
import 'package:petcare/features/hospital_staff/domain/entities/hospital_staff_assignment.dart';
import 'package:petcare/features/hospital_staff/domain/repositories/hospital_staff_assignment_repository.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';
import 'package:petcare/features/veterinary/domain/entities/veterinarian.dart';
import 'package:petcare/features/veterinary/domain/repositories/veterinarian_assignment_repository.dart';

class _ContextStub implements BuildContext {
  const _ContextStub();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'named scanner route has an assignment gate within the session gate',
    () {
      final route =
          AppRouter.routeGenerator(
                auth: MockFirebaseAuth(signedIn: true),
                firestore: FakeFirebaseFirestore(),
              )(const RouteSettings(name: AppRouter.qrHealthPassportScanner))!
              as MaterialPageRoute;
      final session = route.builder(const _ContextStub());
      expect(session, isA<ProtectedSessionGate>());
      final scanner = (session as ProtectedSessionGate).childBuilder(
        const _ContextStub(),
      );
      expect(scanner, isA<QrScannerAccessGate>());
    },
  );

  for (final role in ['owner', 'adoption_provider', 'invalid']) {
    testWidgets('$role cannot open scanner', (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      harness.profile(role);
      await tester.pump();
      expect(find.text('scanner content'), findsNothing);
      expect(find.text('Scanner access unavailable'), findsOneWidget);
      await harness.dispose();
    });
  }

  testWidgets('missing profile keeps scanner closed', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    expect(find.text('scanner content'), findsNothing);
    harness.profiles.changes.add(null);
    await tester.pump();
    expect(find.text('scanner content'), findsNothing);
    expect(find.text('Scanner access unavailable'), findsOneWidget);
    await harness.dispose();
  });

  testWidgets(
    'staff waits for an active assignment and uses header verification',
    (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      harness.profile('veterinary_staff');
      await tester.pump();
      expect(find.text('scanner content'), findsNothing);
      harness.staff.changes.add(
        const HospitalStaffAssignment(
          userId: 'A',
          hospitalId: 'hospital',
          active: false,
        ),
      );
      await tester.pump();
      expect(find.text('scanner content'), findsNothing);
      harness.staff.changes.add(
        const HospitalStaffAssignment(
          userId: 'A',
          hospitalId: 'hospital',
          active: true,
        ),
      );
      await tester.pump();
      expect(find.text('header only'), findsOneWidget);
      await harness.dispose();
    },
  );

  testWidgets('missing staff assignment and assignment error deny scanner', (
    tester,
  ) async {
    final missing = _Harness();
    await missing.pump(tester);
    missing.profile('veterinary_staff');
    await tester.pump();
    missing.staff.changes.add(null);
    await tester.pump();
    expect(find.text('scanner content'), findsNothing);
    await missing.dispose();

    final error = _Harness();
    await error.pump(tester);
    error.profile('veterinary_staff');
    await tester.pump();
    error.staff.changes.addError(
      FirebaseAuthException(code: 'permission-denied'),
    );
    await tester.pump();
    expect(find.text('scanner content'), findsNothing);
    await error.dispose();
  });

  testWidgets('veterinarian waits for assignment and may access records', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.pump(tester);
    harness.profile('veterinarian');
    await tester.pump();
    expect(find.text('scanner content'), findsNothing);
    harness.vet.result.complete(
      const Veterinarian(
        vetId: 'vet',
        hospitalId: 'hospital',
        name: 'Vet',
        active: true,
      ),
    );
    await tester.pump();
    expect(find.text('records allowed'), findsOneWidget);
    await harness.dispose();
  });

  testWidgets(
    'missing vet assignment and profile permission error fail closed',
    (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      harness.profiles.changes.addError(
        FirebaseAuthException(code: 'permission-denied'),
      );
      await tester.pump();
      expect(find.text('scanner content'), findsNothing);
      await harness.dispose();

      final missing = _Harness();
      await missing.pump(tester);
      missing.profile('veterinarian');
      await tester.pump();
      missing.vet.result.complete(null);
      await tester.pump();
      expect(find.text('scanner content'), findsNothing);
      await missing.dispose();
    },
  );

  testWidgets('account switch removes mounted scanner content', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    harness.profile('veterinary_staff');
    await tester.pump();
    harness.staff.changes.add(
      const HospitalStaffAssignment(
        userId: 'A',
        hospitalId: 'hospital',
        active: true,
      ),
    );
    await tester.pump();
    expect(find.text('scanner content'), findsOneWidget);
    harness.auth.switchTo('B');
    await tester.pump();
    expect(find.text('scanner content'), findsNothing);
    await harness.dispose();
  });
}

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
}

class _Auth extends Fake implements FirebaseAuth {
  String? uid = 'A';
  final changes = StreamController<User?>.broadcast(sync: true);
  @override
  User? get currentUser => uid == null ? null : _User(uid!);
  @override
  Stream<User?> authStateChanges() => changes.stream;

  void switchTo(String value) {
    uid = value;
    changes.add(currentUser);
  }
}

class _Profiles implements ProfileRepository {
  final changes = StreamController<UserProfile?>.broadcast(sync: true);
  @override
  Stream<UserProfile?> watchCurrentProfile() => changes.stream;
  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {}
  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {}
}

class _Staff implements HospitalStaffAssignmentRepository {
  final changes = StreamController<HospitalStaffAssignment?>.broadcast(
    sync: true,
  );
  @override
  Stream<HospitalStaffAssignment?> watchCurrentAssignment() => changes.stream;
}

class _Vet implements VeterinarianAssignmentRepository {
  final result = Completer<Veterinarian?>();
  @override
  Future<Veterinarian?> getCurrentAssignment() => result.future;
}

class _Harness {
  final auth = _Auth();
  final profiles = _Profiles();
  final staff = _Staff();
  final vet = _Vet();

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: QrScannerAccessGate(
        auth: auth,
        profileRepository: profiles,
        staffAssignmentRepository: staff,
        veterinarianAssignmentRepository: vet,
        childBuilder: (_, verificationOnly) => Scaffold(
          body: Column(
            children: [
              const Text('scanner content'),
              Text(verificationOnly ? 'header only' : 'records allowed'),
            ],
          ),
        ),
      ),
    ),
  );

  void profile(String role) => profiles.changes.add(
    UserProfile(
      uid: 'A',
      fullName: 'A',
      displayName: 'A',
      email: '',
      phone: '',
      role: role,
      notificationEnabled: true,
    ),
  );

  Future<void> dispose() async {
    await auth.changes.close();
    await profiles.changes.close();
    await staff.changes.close();
  }
}
