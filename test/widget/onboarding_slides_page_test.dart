import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/presentation/pages/onboarding_page.dart';
import 'package:petcare/features/auth/presentation/pages/onboarding_slides_page.dart';

// Custom NavigatorObserver to capture route settings including push, replace, and pop
class _RouteCaptureObserver extends NavigatorObserver {
  _RouteCaptureObserver({
    this.onRoutePushed,
    this.onRouteReplaced,
    this.onRoutePopped,
  });

  final void Function(RouteSettings)? onRoutePushed;
  final void Function(RouteSettings, RouteSettings?)? onRouteReplaced;
  final void Function(RouteSettings)? onRoutePopped;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (onRoutePushed != null) {
      onRoutePushed!(route.settings);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (onRouteReplaced != null && newRoute != null) {
      onRouteReplaced!(newRoute.settings, oldRoute?.settings);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (onRoutePopped != null) {
      onRoutePopped!(route.settings);
    }
  }
}

void main() {
  group('OnboardingSlidesPage widget tests', () {
    testWidgets('Initial render shows slide 1 with correct content', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          home: const OnboardingSlidesPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify slide 1 content
      expect(find.text('All Your Pets.'), findsOneWidget);
      expect(find.text('One Simple Place.'), findsOneWidget);
      expect(
        find.text(
          'Manage multiple pet profiles, keep health records, '
          'track vaccinations and treatments all in one place.',
        ),
        findsOneWidget,
      );

      // Verify page counter
      expect(find.text('1 / 3'), findsOneWidget);

      // Verify primary button shows "Next"
      expect(find.text('Next'), findsOneWidget);

      // Verify Skip button
      expect(find.text('Skip'), findsOneWidget);

      // Verify back button is present (IconButton with tooltip 'Back')
      expect(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Back',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Next from slide 1 navigates to slide 2', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          home: const OnboardingSlidesPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Next" button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify slide 2 content
      expect(find.text('Find Care When'), findsOneWidget);
      expect(find.text('Your Pet Needs It.'), findsOneWidget);
      expect(
        find.text(
          'Discover nearby veterinary hospitals, book appointments '
          'and track your live queue — stress-free.',
        ),
        findsOneWidget,
      );

      // Verify page counter
      expect(find.text('2 / 3'), findsOneWidget);

      // Verify primary button still shows "Next"
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Next from slide 2 navigates to slide 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          home: const OnboardingSlidesPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Advance to slide 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap "Next" again to go to slide 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify slide 3 content
      expect(find.text('Smarter Care.'), findsOneWidget);
      expect(find.text('Every Day.'), findsOneWidget);
      expect(
        find.text(
          'Get AI-powered pet care guidance, view health summaries, '
          'receive preventive insights and even find pets in need '
          'of a loving home.',
        ),
        findsOneWidget,
      );

      // Verify page counter
      expect(find.text('3 / 3'), findsOneWidget);

      // Verify primary button text is now "Get Started"
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Back from slide 2 returns to slide 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          home: const OnboardingSlidesPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to slide 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap back button
      final backButtonFinder = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Back',
      );
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Verify slide 1 content is visible
      expect(find.text('All Your Pets.'), findsOneWidget);
      expect(find.text('One Simple Place.'), findsOneWidget);

      // Verify page counter
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('Back from slide 3 returns to slide 2', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          home: const OnboardingSlidesPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to slide 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap back button
      final backButtonFinder = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Back',
      );
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Verify slide 2 content
      expect(find.text('Find Care When'), findsOneWidget);
      expect(find.text('Your Pet Needs It.'), findsOneWidget);

      // Verify page counter
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('Back from slide 1 pops to Welcome', (tester) async {
      RouteSettings? poppedRouteSettings;
      final observer = _RouteCaptureObserver(
        onRoutePopped: (settings) {
          poppedRouteSettings = settings;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) => const OnboardingPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.onboardingSlides) {
              return MaterialPageRoute(
                builder: (_) => const OnboardingSlidesPage(),
                settings: settings,
              );
            }
            return null;
          },
          navigatorObservers: [observer],
          initialRoute: AppRouter.onboarding,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to onboarding slides
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Now we're on OnboardingSlidesPage (slide 1)
      // Tap back button
      final backButtonFinder = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Back',
      );
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Verify a pop event occurred for OnboardingSlidesPage
      expect(poppedRouteSettings, isNotNull);
      expect(poppedRouteSettings!.name, AppRouter.onboardingSlides);
    });

    testWidgets('Skip navigates to Register', (tester) async {
      RouteSettings? capturedRouteSettings;
      final observer = _RouteCaptureObserver(
        onRoutePushed: (settings) {
          capturedRouteSettings = settings;
        },
        onRouteReplaced: (newSettings, _) {
          capturedRouteSettings = newSettings;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          navigatorObservers: [observer],
          home: const OnboardingSlidesPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Skip"
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.register via pushReplacementNamed
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.register);
      expect(capturedRouteSettings!.arguments, isNull);
    });

    testWidgets('Get Started on slide 3 navigates to Register', (tester) async {
      RouteSettings? capturedRouteSettings;
      final observer = _RouteCaptureObserver(
        onRoutePushed: (settings) {
          capturedRouteSettings = settings;
        },
        onRouteReplaced: (newSettings, _) {
          capturedRouteSettings = newSettings;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          navigatorObservers: [observer],
          home: const OnboardingSlidesPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to slide 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap "Get Started"
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.register via pushReplacementNamed
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.register);
      expect(capturedRouteSettings!.arguments, isNull);
    });

    testWidgets('Login link on slide 3 navigates to Login', (tester) async {
      RouteSettings? capturedRouteSettings;
      final observer = _RouteCaptureObserver(
        onRoutePushed: (settings) {
          capturedRouteSettings = settings;
        },
        onRouteReplaced: (newSettings, _) {
          capturedRouteSettings = newSettings;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.onboardingSlides: (_) =>
                const Scaffold(body: Text('Onboarding Slides')),
          },
          onGenerateRoute: (_) => null,
          navigatorObservers: [observer],
          home: const OnboardingSlidesPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to slide 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Find and tap the Login link (RichText inside TextButton)
      final loginButtonFinder = find.byWidgetPredicate(
        (Widget widget) =>
            widget is TextButton &&
            widget.child is RichText &&
            (widget.child as RichText).text.toPlainText().contains('Login'),
      );
      await tester.ensureVisible(loginButtonFinder);
      await tester.tap(loginButtonFinder);
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.login via pushReplacementNamed
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.login);
      expect(capturedRouteSettings!.arguments, isNull);
    });
  });
}
