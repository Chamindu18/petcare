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
          home: SplashPage(auth: auth),
          routes: {AppRouter.onboarding: (_) => const _TestOnboardingPage()},
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text("Preparing your pet's care..."), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('navigates to onboarding when not authenticated', (
      tester,
    ) async {
      final auth = MockFirebaseAuth(signedIn: false);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(auth: auth),
          routes: {AppRouter.onboarding: (_) => const _TestOnboardingPage()},
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(_TestOnboardingPage), findsOneWidget);
    });

    testWidgets('navigates to home when authenticated', (tester) async {
      final auth = MockFirebaseAuth(signedIn: true);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(auth: auth),
          routes: {AppRouter.home: (_) => const _TestHomePage()},
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(_TestHomePage), findsOneWidget);
    });
  });
}
