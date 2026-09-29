import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/presentation/pages/login_page.dart';
import 'package:petcare/features/auth/presentation/pages/onboarding_page.dart';
import 'package:petcare/features/auth/presentation/pages/register_page.dart';
import 'package:petcare/features/auth/presentation/pages/forgot_password_page.dart';

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
  });
}

class _BuildContextStub implements BuildContext {
  const _BuildContextStub();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
