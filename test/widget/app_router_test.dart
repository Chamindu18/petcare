import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_listing.dart';
import 'package:petcare/features/auth/presentation/pages/login_page.dart';
import 'package:petcare/features/auth/presentation/pages/onboarding_page.dart';
import 'package:petcare/features/auth/presentation/pages/register_page.dart';
import 'package:petcare/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:petcare/features/pets/domain/entities/pet.dart';
import 'package:petcare/features/pets/domain/usecases/create_pet.dart';
import 'package:petcare/features/pets/domain/usecases/delete_pet.dart';
import 'package:petcare/features/pets/domain/usecases/get_pets.dart';
import 'package:petcare/features/pets/domain/usecases/update_pet.dart';
import 'package:petcare/features/pets/presentation/providers/pets_controller.dart';
import 'package:petcare/features/pets/domain/repositories/pet_repository.dart';

void main() {
  group('AppRouter authentication guard', () {
    late MockFirebaseAuth mockAuth;
    late RouteFactory routeGenerator;

    setUp(() {
      mockAuth = MockFirebaseAuth(signedIn: false);
      routeGenerator = AppRouter.routeGenerator(auth: mockAuth);
    });

    group(
      'unauthenticated access to protected routes redirects to LoginPage',
      () {
        test('home returns LoginPage route', () {
          final route = routeGenerator(
            const RouteSettings(name: AppRouter.home),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.home);
          final widget = materialRoute.builder(const _BuildContextStub());
          expect(widget, isA<LoginPage>());
        });

        test('myPets returns LoginPage route', () {
          final route = routeGenerator(
            const RouteSettings(name: AppRouter.myPets),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.myPets);
          final widget = materialRoute.builder(const _BuildContextStub());
          expect(widget, isA<LoginPage>());
        });

        test('notifications returns LoginPage route', () {
          final route = routeGenerator(
            const RouteSettings(name: AppRouter.notifications),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.notifications);
          final widget = materialRoute.builder(const _BuildContextStub());
          expect(widget, isA<LoginPage>());
        });

        test('addPet returns LoginPage route with null arguments', () {
          final route = routeGenerator(
            const RouteSettings(name: AppRouter.addPet, arguments: null),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.addPet);
          expect(materialRoute.settings.arguments, isNull);
          final widget = materialRoute.builder(const _BuildContextStub());
          expect(widget, isA<LoginPage>());
        });

        test('adoptionPetDetails returns LoginPage route with arguments', () {
          const arguments = 'test-listing-id';
          final route = routeGenerator(
            const RouteSettings(
              name: AppRouter.adoptionPetDetails,
              arguments: arguments,
            ),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.adoptionPetDetails);
          expect(materialRoute.settings.arguments, arguments);
          final widget = materialRoute.builder(const _BuildContextStub());
          expect(widget, isA<LoginPage>());
        });

        test('myAdoptionListings returns LoginPage route', () {
          final route = routeGenerator(
            const RouteSettings(name: AppRouter.myAdoptionListings),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.myAdoptionListings);
          final widget = materialRoute.builder(const _BuildContextStub());
          expect(widget, isA<LoginPage>());
        });

        test('petProfile returns LoginPage route with null arguments', () {
          final route = routeGenerator(
            const RouteSettings(name: AppRouter.petProfile, arguments: null),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.petProfile);
          expect(materialRoute.settings.arguments, isNull);
          final widget = materialRoute.builder(const _BuildContextStub());
          expect(widget, isA<LoginPage>());
        });
      },
    );

    group('RouteSettings preserved on unauthenticated redirect', () {
      test('RouteSettings.name preserved on redirect', () {
        const arguments = 'test-listing-id';
        final route = routeGenerator(
          const RouteSettings(
            name: AppRouter.adoptionPetDetails,
            arguments: arguments,
          ),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        expect(materialRoute.settings.name, AppRouter.adoptionPetDetails);
        expect(materialRoute.settings.arguments, arguments);
      });

      test('RouteSettings.arguments preserved on redirect', () {
        final route = routeGenerator(
          const RouteSettings(name: AppRouter.petProfile, arguments: null),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        expect(materialRoute.settings.arguments, isNull);
      });
    });

    group('public routes accessible when signed out', () {
      test('login route returns LoginPage', () {
        final builder = AppRouter.routes[AppRouter.login];
        expect(builder, isNotNull);
        final widget = builder!(const _BuildContextStub());
        expect(widget, isA<LoginPage>());
      });

      test('register route returns RegisterPage', () {
        final builder = AppRouter.routes[AppRouter.register];
        expect(builder, isNotNull);
        final widget = builder!(const _BuildContextStub());
        expect(widget, isA<RegisterPage>());
      });

      test('forgotPassword route returns ForgotPasswordPage', () {
        final builder = AppRouter.routes[AppRouter.forgotPassword];
        expect(builder, isNotNull);
        final widget = builder!(const _BuildContextStub());
        expect(widget, isA<ForgotPasswordPage>());
      });

      test('onboarding route returns OnboardingPage', () {
        final builder = AppRouter.routes[AppRouter.onboarding];
        expect(builder, isNotNull);
        final widget = builder!(const _BuildContextStub());
        expect(widget, isA<OnboardingPage>());
      });
    });

    group('authenticated access to protected routes', () {
      late MockFirebaseAuth signedInAuth;
      late RouteFactory signedInRouteGenerator;

      setUp(() {
        signedInAuth = MockFirebaseAuth(signedIn: true);
        signedInRouteGenerator = AppRouter.routeGenerator(auth: signedInAuth);
      });

      test('home returns route for /home (not LoginPage redirect)', () {
        final route = signedInRouteGenerator(
          const RouteSettings(name: AppRouter.home),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        expect(materialRoute.settings.name, AppRouter.home);
        expect(materialRoute.settings.arguments, isNull);
      });

      test('myPets returns route for /my-pets (not LoginPage redirect)', () {
        final route = signedInRouteGenerator(
          const RouteSettings(name: AppRouter.myPets),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        expect(materialRoute.settings.name, AppRouter.myPets);
        expect(materialRoute.settings.arguments, isNull);
      });

      test('notifications returns route for /notifications (not LoginPage redirect)', () {
        final route = signedInRouteGenerator(
          const RouteSettings(name: AppRouter.notifications),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        expect(materialRoute.settings.name, AppRouter.notifications);
        expect(materialRoute.settings.arguments, isNull);
      });

      test(
        'addPet returns route for /add-pet with null controller argument',
        () {
          final route = signedInRouteGenerator(
            const RouteSettings(name: AppRouter.addPet, arguments: null),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.addPet);
          expect(materialRoute.settings.arguments, isNull);
        },
      );

      test(
        'addPet returns route for /add-pet with preserved controller argument',
        () {
          final testController = _FakePetsController();
          final route = signedInRouteGenerator(
            RouteSettings(name: AppRouter.addPet, arguments: testController),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.addPet);
          expect(materialRoute.settings.arguments, testController);
        },
      );

      test(
        'petProfile returns route for /pet-profile with preserved Pet argument',
        () {
          final testPet = Pet(
            petId: 'pet-123',
            ownerId: 'owner-123',
            name: 'Buddy',
            species: 'dog',
            breed: 'Golden Retriever',
            dob: DateTime(2020, 1, 15),
            gender: 'male',
            weight: 30.5,
            imageUrl: '',
            notes: '',
            status: 'active',
          );
          final route = signedInRouteGenerator(
            RouteSettings(name: AppRouter.petProfile, arguments: testPet),
          );
          expect(route, isA<MaterialPageRoute>());
          final materialRoute = route as MaterialPageRoute;
          expect(materialRoute.settings.name, AppRouter.petProfile);
          expect(materialRoute.settings.arguments, testPet);
        },
      );

      test('myAdoptionListings returns route for /my-adoption-listings', () {
        final route = signedInRouteGenerator(
          const RouteSettings(name: AppRouter.myAdoptionListings),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        expect(materialRoute.settings.name, AppRouter.myAdoptionListings);
        expect(materialRoute.settings.arguments, isNull);
      });

      test('adoptionPetDetails returns route for /adoption-pet-details with preserved listingId', () {
        const listingId = 'adoption-listing-456';
        final route = signedInRouteGenerator(
          RouteSettings(
            name: AppRouter.adoptionPetDetails,
            arguments: listingId,
          ),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        expect(materialRoute.settings.name, AppRouter.adoptionPetDetails);
        expect(materialRoute.settings.arguments, listingId);
      });

      test('adoptionRequest returns route for /adoption-request with preserved AdoptionListing argument', () {
        final testListing = AdoptionListing(
          listingId: 'listing-789',
          providerId: 'provider-123',
          petName: 'Luna',
          species: 'cat',
          breed: 'Siamese',
          ageDescription: '6 months',
          gender: 'female',
          description: 'Friendly kitten',
          location: 'Colombo',
          imageAsset: null,
          status: 'available',
          contactNote: null,
          createdAt: DateTime(2023, 6, 1),
          updatedAt: DateTime(2023, 6, 1),
        );
        final route = signedInRouteGenerator(
          RouteSettings(
            name: AppRouter.adoptionRequest,
            arguments: testListing,
          ),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        expect(materialRoute.settings.name, AppRouter.adoptionRequest);
        expect(materialRoute.settings.arguments, testListing);
      });
    });
  });
}

class _BuildContextStub implements BuildContext {
  const _BuildContextStub();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

class _FakePetsController extends PetsController {
  _FakePetsController()
    : super(
        CreatePet(_FakePetRepository()),
        GetPets(_FakePetRepository()),
        UpdatePet(_FakePetRepository()),
        DeletePet(_FakePetRepository()),
      );
}
