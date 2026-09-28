import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/presentation/pages/password_reset_success_page.dart';

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
  group('PasswordResetSuccessPage widget tests', () {
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
          },
          home: const PasswordResetSuccessPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify key texts are displayed
      // The heading is "Password Reset\nSuccessful!" (with newline)
      expect(find.textContaining('Password Reset'), findsOneWidget);
      expect(find.textContaining('Successful!'), findsOneWidget);
      expect(
        find.text(
          'Your password has been changed successfully. '
          'You can now log in to your account with your new password.',
        ),
        findsOneWidget,
      );
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('Back to Login navigates correctly', (tester) async {
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
            AppRouter.checkEmail: (_) =>
                const Scaffold(body: Text('Check Email')),
          },
          navigatorObservers: [observer],
          home: const PasswordResetSuccessPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to and tap "Back to Login"
      await tester.ensureVisible(find.text('Back to Login'));
      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.login by capturing RouteSettings
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.login);
      expect(capturedRouteSettings!.arguments, isNull);
    });
  });
}
