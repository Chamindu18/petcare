import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/auth/presentation/pages/check_email_page.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.shouldSucceed = true, this.delayFuture});

  final bool shouldSucceed;
  final Future<void>? delayFuture;

  @override
  Future<void> registerOwner({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (delayFuture != null) {
      await delayFuture!;
    }
    throw AuthException('Not implemented');
  }

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (delayFuture != null) {
      await delayFuture!;
    }
    throw AuthException('Not implemented');
  }

  @override
  Future<void> signInWithGoogle() async {
    if (delayFuture != null) {
      await delayFuture!;
    }
    throw AuthException('Not implemented');
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (delayFuture != null) {
      await delayFuture!;
    }
    if (!shouldSucceed) {
      throw AuthException('Failed to send reset link');
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {}
}

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
  group('CheckEmailPage widget tests', () {
    testWidgets('email display', (tester) async {
      final repo = _FakeAuthRepository();

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
          onGenerateRoute: (_) => null,
          home: CheckEmailPage(email: 'test@example.com', authRepository: repo),
        ),
      );

      await tester.pumpAndSettle();

      // Verify email is displayed
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('back to login navigation', (tester) async {
      final repo = _FakeAuthRepository();
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
          onGenerateRoute: (_) => null,
          navigatorObservers: [observer],
          home: CheckEmailPage(email: 'test@example.com', authRepository: repo),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Back to Login"
      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.login
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.login);
      expect(capturedRouteSettings!.arguments, isNull);
    });

    testWidgets('resend email loading state', (tester) async {
      final completer = Completer<void>();
      final repo = _FakeAuthRepository(
        shouldSucceed: true,
        delayFuture: completer.future,
      );

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
          onGenerateRoute: (_) => null,
          home: CheckEmailPage(email: 'test@example.com', authRepository: repo),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to and tap "Resend Email"
      await tester.ensureVisible(find.text('Resend Email'));
      await tester.tap(find.text('Resend Email'));
      await tester.pump();

      // Verify loading state: button disabled, CircularProgressIndicator visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The button should be disabled (onPressed == null)
      final buttonFinder = find.byType(OutlinedButton);
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<OutlinedButton>(buttonFinder);
      expect(button.onPressed, isNull);

      // Complete the fake future
      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
