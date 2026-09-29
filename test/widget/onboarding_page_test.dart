import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/presentation/pages/onboarding_page.dart';

// Custom NavigatorObserver to capture route settings
class _RouteCaptureObserver extends NavigatorObserver {
  _RouteCaptureObserver(this.onRoutePushed);

  final void Function(RouteSettings) onRoutePushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRoutePushed(route.settings);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      onRoutePushed(newRoute.settings);
    }
  }
}

void main() {
  group('OnboardingPage widget tests', () {
    testWidgets('OnboardingPage renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          home: const OnboardingPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify key texts are displayed
      expect(find.text('Better Care'), findsOneWidget);
      expect(find.text('Starts Here.'), findsOneWidget);
      expect(
        find.text(
          'Trusted support, expert care, and a healthier, '
          'happier life for your pet.',
        ),
        findsOneWidget,
      );
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
    });

    testWidgets('Get Started navigates to onboarding slides', (tester) async {
      RouteSettings? capturedRouteSettings;
      final observer = _RouteCaptureObserver((settings) {
        capturedRouteSettings = settings;
      });

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          navigatorObservers: [observer],
          home: const OnboardingPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Get Started" button
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.onboardingSlides by capturing RouteSettings
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.onboardingSlides);
      expect(capturedRouteSettings!.arguments, isNull);
    });

    testWidgets('Already have an account navigates to Login', (tester) async {
      RouteSettings? capturedRouteSettings;
      final observer = _RouteCaptureObserver((settings) {
        capturedRouteSettings = settings;
      });

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          navigatorObservers: [observer],
          home: const OnboardingPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Already have an account?" button
      await tester.tap(find.text('Already have an account?'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.login by capturing RouteSettings
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.login);
      expect(capturedRouteSettings!.arguments, isNull);
    });
  });
}
