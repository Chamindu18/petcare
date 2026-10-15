import 'dart:async';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/presentation/pages/splash_page.dart';

class _TestOnboardingPage extends StatelessWidget {
  const _TestOnboardingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Onboarding'));
  }
}

class _TestHomePage extends StatelessWidget {
  const _TestHomePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }
}

void main() {
  group('SplashPage', () {
    testWidgets('shows PetCare+ logo and loading message', (tester) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(auth: auth, startupFuture: Future.value(false)),
          routes: {AppRouter.onboarding: (_) => const _TestOnboardingPage()},
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.home) {
              return MaterialPageRoute(
                builder: (_) => const _TestHomePage(),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('navigates to onboarding when not authenticated', (
      tester,
    ) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(auth: auth, startupFuture: Future.value(false)),
          routes: {AppRouter.onboarding: (_) => const _TestOnboardingPage()},
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.home) {
              return MaterialPageRoute(
                builder: (_) => const _TestHomePage(),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(_TestOnboardingPage), findsOneWidget);
    });

    testWidgets('navigates to home when authenticated', (tester) async {
      final auth = MockFirebaseAuth(signedIn: true);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(auth: auth, startupFuture: Future.value(false)),
          routes: {AppRouter.onboarding: (_) => const _TestOnboardingPage()},
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.home) {
              return MaterialPageRoute(
                builder: (_) => const _TestHomePage(),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(_TestHomePage), findsOneWidget);
    });

    testWidgets('waits for startupFuture before navigating', (tester) async {
      final auth = MockFirebaseAuth(signedIn: false);
      final completer = Completer<bool>();

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(auth: auth, startupFuture: completer.future),
          routes: {AppRouter.onboarding: (_) => const _TestOnboardingPage()},
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.home) {
              return MaterialPageRoute(
                builder: (_) => const _TestHomePage(),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );

      // Before completing the future, should still be on splash
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(_TestOnboardingPage), findsNothing);

      completer.complete(false);
      await tester.pumpAndSettle();

      expect(find.byType(_TestOnboardingPage), findsOneWidget);
    });

    testWidgets('suppresses navigation when deep link handled', (tester) async {
      final auth = MockFirebaseAuth(signedIn: false);
      final completer = Completer<bool>();

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(auth: auth, startupFuture: completer.future),
          routes: {AppRouter.onboarding: (_) => const _TestOnboardingPage()},
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.home) {
              return MaterialPageRoute(
                builder: (_) => const _TestHomePage(),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );

      // Before completing the future, should still be on splash
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(_TestOnboardingPage), findsNothing);

      // Complete with true (deep link handled) - should suppress navigation
      completer.complete(true);
      // Use pump instead of pumpAndSettle because the splash page has an
      // indefinitely animated CircularProgressIndicator that prevents
      // pumpAndSettle from completing.
      await tester.pump(const Duration(milliseconds: 100));

      // Should remain on splash (which will be replaced by the deep link navigation)
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(_TestOnboardingPage), findsNothing);
    });
  });
}
