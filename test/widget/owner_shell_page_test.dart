import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/home/presentation/pages/home_page.dart';
import 'package:petcare/features/home/presentation/pages/owner_shell_page.dart';
import 'package:petcare/features/notifications/domain/entities/notification.dart'
    as notification_entity;
import 'package:petcare/features/notifications/domain/repositories/notification_repository.dart';
import 'package:petcare/features/pets/domain/entities/pet.dart';
import 'package:petcare/features/pets/domain/repositories/pet_image_repository.dart';
import 'package:petcare/features/pets/domain/repositories/pet_repository.dart';
import 'package:petcare/features/pets/domain/usecases/create_pet.dart';
import 'package:petcare/features/pets/domain/usecases/delete_pet.dart';
import 'package:petcare/features/pets/domain/usecases/delete_pet_image.dart';
import 'package:petcare/features/pets/domain/usecases/get_pets.dart';
import 'package:petcare/features/pets/domain/usecases/update_pet.dart';
import 'package:petcare/features/pets/domain/usecases/upload_pet_image.dart';
import 'package:petcare/features/pets/presentation/pages/my_pets_page.dart';
import 'package:petcare/features/pets/presentation/providers/pets_controller.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';
import 'package:petcare/features/profile/presentation/pages/profile_page.dart';

class _FakePetRepository implements PetRepository {
  @override
  Future<Pet> createPet(Pet pet) async => pet;

  @override
  Future<List<Pet>> getPets() async => [];

  @override
  Future<Pet?> getPetById(String petId) async => null;

  @override
  Future<void> updatePet(Pet pet) async {}

  @override
  Future<void> deletePet(String petId) async {}
}

class _FakePetImageRepository implements PetImageRepository {
  @override
  Future<String> uploadPetImage({
    required String petId,
    required Uint8List bytes,
  }) async => 'https://fake.image.url/$petId.jpg';

  @override
  Future<void> deletePetImage({required String imageUrl}) async {}
}

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository();

  @override
  Stream<List<notification_entity.Notification>> watchNotifications() {
    return Stream.value(const []);
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {}

  @override
  Future<void> markAllAsRead() async {}
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository();

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    return Stream.value(null);
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
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {}
}

class _FakePetsController extends PetsController {
  _FakePetsController()
    : super(
        CreatePet(_FakePetRepository()),
        GetPets(_FakePetRepository()),
        UpdatePet(_FakePetRepository()),
        DeletePet(_FakePetRepository()),
        UploadPetImage(_FakePetImageRepository()),
        DeletePetImage(_FakePetImageRepository()),
      );

  bool _disposed = false;

  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _RouteCapture {
  RouteSettings? settings;
}

void main() {
  group('OwnerShellPage', () {
    late MockFirebaseAuth signedInAuth;
    late _RouteCapture routeCapture;

    setUp(() {
      signedInAuth = MockFirebaseAuth(signedIn: true);
      routeCapture = _RouteCapture();
    });

    Widget buildTestApp({
      required PetsController petsController,
      FirebaseAuth? auth,
      NotificationRepository? notificationRepository,
      ProfileRepository? profileRepository,
      AuthRepository? authRepository,
    }) {
      return MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRouter.addPet) {
            routeCapture.settings = settings;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Add Pet')),
              settings: settings,
            );
          }
          if (settings.name == AppRouter.notifications) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Notifications')),
              settings: settings,
            );
          }
          if (settings.name == AppRouter.editProfile) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Edit Profile')),
              settings: settings,
            );
          }
          if (settings.name == AppRouter.notificationSettings) {
            return MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(body: Text('Notification Settings')),
              settings: settings,
            );
          }
          if (settings.name == AppRouter.privacySecurity) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Privacy Security')),
              settings: settings,
            );
          }
          if (settings.name == AppRouter.helpSupport) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Help Support')),
              settings: settings,
            );
          }
          if (settings.name == AppRouter.aboutPetCare) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('About PetCare')),
              settings: settings,
            );
          }
          return AppRouter.routeGenerator(auth: auth ?? signedInAuth)(settings);
        },
        home: OwnerShellPage(
          petsController: petsController,
          auth: auth ?? signedInAuth,
          notificationRepository: notificationRepository ?? _FakeNotificationRepository(),
          profileRepository: profileRepository ?? _FakeProfileRepository(),
          authRepository: authRepository ?? _FakeAuthRepository(),
        ),
      );
    }

    testWidgets('renders with injected PetsController', (tester) async {
      final fakeController = _FakePetsController();

      await tester.pumpWidget(buildTestApp(petsController: fakeController));
      await tester.pumpAndSettle();

      expect(find.byType(OwnerShellPage), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsWidgets);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Pets'), findsOneWidget);
      expect(find.text('Appointments').first, findsOneWidget);
      expect(find.text('AI Hub'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('switches between bottom navigation tabs', (tester) async {
      final fakeController = _FakePetsController();

      await tester.pumpWidget(buildTestApp(petsController: fakeController));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(MyPetsPage), findsNothing);
      expect(find.byType(ProfilePage), findsNothing);
      expect(find.text('This section will be available soon.'), findsNothing);

      await tester.tap(find.text('My Pets').first);
      await tester.pumpAndSettle();
      expect(find.byType(MyPetsPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      await tester.tap(find.text('Appointments').first);
      await tester.pumpAndSettle();
      expect(find.text('This section will be available soon.'), findsOneWidget);
      expect(find.text('Appointments').first, findsOneWidget);

      await tester.tap(find.text('AI Hub').first);
      await tester.pumpAndSettle();
      expect(find.text('This section will be available soon.'), findsOneWidget);
      expect(find.text('AI Hub').first, findsOneWidget);

      await tester.tap(find.text('Profile').first);
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);

      await tester.tap(find.text('Home').first);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('uses injected PetsController without disposing it', (
      tester,
    ) async {
      final fakeController = _FakePetsController();

      await tester.pumpWidget(buildTestApp(petsController: fakeController));
      await tester.pumpAndSettle();

      expect(fakeController.disposed, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(fakeController.disposed, isFalse);
    });

    testWidgets('passes the injected PetsController when opening Add Pet', (
      tester,
    ) async {
      final fakeController = _FakePetsController();

      await tester.pumpWidget(buildTestApp(petsController: fakeController));
      await tester.pumpAndSettle();

      final addPetButton = find.byIcon(Icons.add_rounded);
      expect(addPetButton, findsOneWidget);

      await tester.tap(addPetButton);
      await tester.pumpAndSettle();

      expect(routeCapture.settings, isNotNull);
      expect(routeCapture.settings!.name, AppRouter.addPet);
      expect(routeCapture.settings!.arguments, same(fakeController));
    });

    // TEST 5 and TEST 6 intentionally omitted:
    // - 'renders without an injected PetsController' requires OwnerShellPage to
    //   create FirebasePetRepository with FirebaseAuth.instance/FirebaseFirestore.instance
    //   which needs Firebase.initializeApp(). The current architecture doesn't allow
    //   injecting fakes for the internal creation path without production changes.
    // - 'disposes internally created controller' similarly cannot be observed
    //   without exposing private state or modifying OwnerShellPage.
  });
}