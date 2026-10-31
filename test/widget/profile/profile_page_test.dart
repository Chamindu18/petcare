import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';
import 'package:petcare/features/profile/presentation/pages/profile_page.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.profile, this.emitError = false});

  final UserProfile? profile;
  final bool emitError;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    if (emitError) {
      return Stream<UserProfile?>.error(
        ProfileRepositoryException('Test error'),
      );
    }

    return Stream.value(profile);
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {}

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {}
}

class _FakeAuthRepository implements AuthRepository {
  bool signedOut = false;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<void> registerOwner({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {}

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {}
}

void main() {
  group('ProfilePage', () {
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

    Future<void> pumpProfilePage(
      WidgetTester tester, {
      String? photoUrl,
      bool emitError = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            profileRepository: _FakeProfileRepository(
              profile: createProfile(),
              emitError: emitError,
            ),
            authRepository: _FakeAuthRepository(),
            photoUrl: photoUrl,
          ),
        ),
      );

      await tester.pump();
    }

    testWidgets('shows profile information and settings', (tester) async {
      await pumpProfilePage(tester);

      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('About PetCare+'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Log Out'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('shows error state when profile loading fails', (tester) async {
      await pumpProfilePage(tester, emitError: true);

      expect(find.text('Unable to load your profile'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog', (tester) async {
      final authRepository = _FakeAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            profileRepository: _FakeProfileRepository(profile: createProfile()),
            authRepository: authRepository,
          ),
        ),
      );

      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Log Out'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to log out of your PetCare+ account?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      expect(authRepository.signedOut, isFalse);
    });

    testWidgets('displays network profile image when photo URL is provided', (
      tester,
    ) async {
      const photoUrl = 'https://example.com/profile-photo.png';

      await pumpProfilePage(tester, photoUrl: photoUrl);

      final imageFinder = find.byWidgetPredicate((widget) {
        return widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url == photoUrl;
      });

      expect(imageFinder, findsOneWidget);
    });

    testWidgets('displays fallback avatar when photo URL is null', (
      tester,
    ) async {
      await pumpProfilePage(tester);

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('displays fallback avatar when photo URL is blank', (
      tester,
    ) async {
      await pumpProfilePage(tester, photoUrl: '   ');

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('displays fallback avatar when network image fails', (
      tester,
    ) async {
      await pumpProfilePage(
        tester,
        photoUrl: 'https://example.invalid/profile-photo.png',
      );

      // The Flutter widget-test HTTP client returns a failed response.
      // The Image.network errorBuilder should display the fallback icon.
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });
  });
}
