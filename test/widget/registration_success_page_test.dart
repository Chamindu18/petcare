import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/presentation/pages/registration_success_page.dart';

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
  group('RegistrationSuccessPage widget tests', () {
    testWidgets('UI renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.checkEmail: (_) =>
                const Scaffold(body: Text('Check Email')),
            AppRouter.passwordResetSuccess: (_) =>
                const Scaffold(body: Text('Success')),
          },
          home: const RegistrationSuccessPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to make all content visible
      await tester.ensureVisible(find.text('Account Created!'));
      await tester.pumpAndSettle();

      // Verify key texts are displayed
      expect(find.text('Account Created!'), findsOneWidget);
      expect(
        find.text(
          'Welcome to PetCare+! Your account has been '
          'created successfully. Let\u2019s get started on a '
          'healthier, happier journey together.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('all set!'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);

      // Verify "Log In" text is displayed (inside TextButton with RichText)
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is TextButton &&
              widget.child is RichText &&
              (widget.child as RichText).text.toPlainText().contains('Log In'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"Go to Home" navigates to Home', (tester) async {
      RouteSettings? capturedRouteSettings;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.checkEmail: (_) =>
                const Scaffold(body: Text('Check Email')),
            AppRouter.passwordResetSuccess: (_) =>
                const Scaffold(body: Text('Success')),
            // AppRouter.home intentionally omitted to allow onGenerateRoute to handle it
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.home) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Home')),
                settings: settings,
              );
            }
            return null;
          },
          navigatorObservers: [
            _RouteCaptureObserver((settings) {
              capturedRouteSettings = settings;
            }),
          ],
          home: const RegistrationSuccessPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Go to Home"
      await tester.ensureVisible(find.text('Go to Home'));
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.home by capturing RouteSettings
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.home);
      expect(capturedRouteSettings!.arguments, isNull);
    });

    testWidgets('"Already have an account? Log In" navigates to Login', (
      tester,
    ) async {
      RouteSettings? capturedRouteSettings;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            AppRouter.checkEmail: (_) =>
                const Scaffold(body: Text('Check Email')),
            AppRouter.passwordResetSuccess: (_) =>
                const Scaffold(body: Text('Success')),
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.login) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Login')),
                settings: settings,
              );
            }
            return null;
          },
          navigatorObservers: [
            _RouteCaptureObserver((settings) {
              capturedRouteSettings = settings;
            }),
          ],
          home: const RegistrationSuccessPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to and tap "Log In" link (inside TextButton with RichText)
      final logInButtonFinder = find.byWidgetPredicate(
        (Widget element) =>
            element is TextButton &&
            element.child is RichText &&
            (element.child as RichText).text.toPlainText().contains('Log In'),
      );
      await tester.ensureVisible(logInButtonFinder);
      await tester.tap(logInButtonFinder);
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.login
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.login);
      expect(capturedRouteSettings!.arguments, isNull);
    });
  });
}
