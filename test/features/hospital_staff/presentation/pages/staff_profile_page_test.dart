import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_profile_page.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';

const _staffProfile = UserProfile(
  uid: 'staff-001',
  fullName: 'Test Staff Member',
  displayName: 'Test Staff Member',
  email: 'staff@example.com',
  phone: '0771234567',
  role: 'veterinary_staff',
  notificationEnabled: true,
);

const _hospital = Hospital(
  hospitalId: 'hospital-001',
  name: 'PetCare Animal Hospital',
  location: 'Colombo, Sri Lanka',
  contact: '0112345678',
  hours: 'Monday - Saturday, 8 AM - 6 PM',
  active: true,
);

class _FakeProfileRepository implements ProfileRepository {
  int watchCount = 0;
  int updateCount = 0;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    watchCount++;
    return Stream<UserProfile?>.value(_staffProfile);
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    updateCount++;
  }

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {
    updateCount++;
  }
}

class _FakeHospitalRepository implements HospitalRepository {
  _FakeHospitalRepository({this.hospital = _hospital});

  final Hospital? hospital;

  int callCount = 0;
  final List<String> requestedHospitalIds = [];

  @override
  Future<Hospital?> getHospitalById(String hospitalId) async {
    callCount++;
    requestedHospitalIds.add(hospitalId);
    return hospital;
  }

  @override
  Future<List<Hospital>> getHospitals() async => [];
}

class _FakeAuthRepository implements AuthRepository {
  bool shouldFailSignOut = false;
  int signOutCount = 0;

  @override
  Future<void> signOut() async {
    signOutCount++;

    if (shouldFailSignOut) {
      throw const AuthException('Simulated logout failure');
    }
  }

  @override
  Future<void> registerOwner({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithGoogle() async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    throw UnimplementedError();
  }
}

/// Mounts the staff Profile with fake dependencies and a login route.
///
/// All tests run without Firebase network access.
Future<void> _pumpProfile(
  WidgetTester tester, {
  required _FakeProfileRepository profileRepository,
  required _FakeHospitalRepository hospitalRepository,
  required _FakeAuthRepository authRepository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StaffProfilePage(
          hospitalId: 'hospital-001',
          profileRepository: profileRepository,
          hospitalRepository: hospitalRepository,
          authRepository: authRepository,
        ),
      ),
      routes: {
        AppRouter.login: (_) =>
            const Scaffold(body: Center(child: Text('Test Login Destination'))),
      },
    ),
  );

  await tester.pumpAndSettle();
}

/// Scrolls the lazily built Profile list until a target exists.
///
/// A widget below the viewport may not yet be built, so ensureVisible()
/// alone cannot locate it.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 30,
  );

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

/// Opens the logout confirmation dialog.
Future<void> _tapLogout(WidgetTester tester) async {
  final logoutButton = find.widgetWithText(OutlinedButton, 'Log Out');

  await _scrollTo(tester, logoutButton);

  await tester.tap(logoutButton);
  await tester.pumpAndSettle();
}

void main() {
  group('StaffProfilePage', () {
    testWidgets('displays authenticated staff and assigned hospital details', (
      tester,
    ) async {
      final profileRepository = _FakeProfileRepository();
      final hospitalRepository = _FakeHospitalRepository();
      final authRepository = _FakeAuthRepository();

      await _pumpProfile(
        tester,
        profileRepository: profileRepository,
        hospitalRepository: hospitalRepository,
        authRepository: authRepository,
      );

      expect(find.text('Staff Profile'), findsOneWidget);
      expect(find.text('Test Staff Member'), findsOneWidget);
      expect(find.text('staff@example.com'), findsOneWidget);
      expect(find.text('Veterinary Staff'), findsOneWidget);
      expect(find.text('0771234567'), findsOneWidget);

      await _scrollTo(tester, find.text('PetCare Animal Hospital'));

      expect(find.text('PetCare Animal Hospital'), findsOneWidget);

      await _scrollTo(tester, find.text('Operating Hours'));

      expect(find.text('hospital-001'), findsOneWidget);
      expect(find.text('Colombo, Sri Lanka'), findsOneWidget);
      expect(find.text('0112345678'), findsOneWidget);
      expect(find.text('Monday - Saturday, 8 AM - 6 PM'), findsOneWidget);

      expect(profileRepository.watchCount, 1);
      expect(hospitalRepository.callCount, 1);
      expect(hospitalRepository.requestedHospitalIds, ['hospital-001']);

      expect(profileRepository.updateCount, 0);
      expect(authRepository.signOutCount, 0);
    });

    testWidgets('does not permit editing the hospital assignment', (
      tester,
    ) async {
      final profileRepository = _FakeProfileRepository();

      await _pumpProfile(
        tester,
        profileRepository: profileRepository,
        hospitalRepository: _FakeHospitalRepository(),
        authRepository: _FakeAuthRepository(),
      );

      await _scrollTo(
        tester,
        find.text('Managed by authorized administration'),
      );

      expect(find.text('Managed by authorized administration'), findsOneWidget);

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(profileRepository.updateCount, 0);
    });

    testWidgets('cancelling logout keeps staff signed in', (tester) async {
      final authRepository = _FakeAuthRepository();

      await _pumpProfile(
        tester,
        profileRepository: _FakeProfileRepository(),
        hospitalRepository: _FakeHospitalRepository(),
        authRepository: authRepository,
      );

      await _tapLogout(tester);

      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(authRepository.signOutCount, 0);
      expect(find.text('Test Login Destination'), findsNothing);
      expect(find.byType(StaffProfilePage), findsOneWidget);
    });

    testWidgets('confirming logout signs out and navigates to Login', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository();

      await _pumpProfile(
        tester,
        profileRepository: _FakeProfileRepository(),
        hospitalRepository: _FakeHospitalRepository(),
        authRepository: authRepository,
      );

      await _tapLogout(tester);

      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(authRepository.signOutCount, 1);
      expect(find.text('Test Login Destination'), findsOneWidget);
      expect(find.byType(StaffProfilePage), findsNothing);
    });

    testWidgets('failed logout shows an error without navigating away', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository()..shouldFailSignOut = true;

      await _pumpProfile(
        tester,
        profileRepository: _FakeProfileRepository(),
        hospitalRepository: _FakeHospitalRepository(),
        authRepository: authRepository,
      );

      await _tapLogout(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(authRepository.signOutCount, 1);
      expect(find.byType(StaffProfilePage), findsOneWidget);
      expect(find.text('Test Login Destination'), findsNothing);
      expect(find.text('Unable to log out. Please try again.'), findsOneWidget);
    });

    testWidgets('does not expose details from an incorrect hospital', (
      tester,
    ) async {
      final hospitalRepository = _FakeHospitalRepository(
        hospital: const Hospital(
          hospitalId: 'hospital-002',
          name: 'Other Hospital',
          location: 'Kandy',
          contact: '0000000000',
          hours: 'Always',
          active: true,
        ),
      );

      await _pumpProfile(
        tester,
        profileRepository: _FakeProfileRepository(),
        hospitalRepository: hospitalRepository,
        authRepository: _FakeAuthRepository(),
      );

      await _scrollTo(
        tester,
        find.text('Your assigned hospital is currently unavailable.'),
      );

      expect(find.text('Other Hospital'), findsNothing);
      expect(
        find.text('Your assigned hospital is currently unavailable.'),
        findsOneWidget,
      );

      expect(hospitalRepository.requestedHospitalIds, ['hospital-001']);
    });
  });
}
