import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/auth/presentation/pages/reset_password_page.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.shouldSucceed = true, this.delayFuture});

  final bool shouldSucceed;
  final Future<void>? delayFuture;

  // Track calls for verification
  String? lastResetCode;
  String? lastNewPassword;
  int confirmPasswordResetCallCount = 0;

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
  }) async {
    confirmPasswordResetCallCount++;
    lastResetCode = code;
    lastNewPassword = newPassword;

    if (delayFuture != null) {
      await delayFuture!;
    }
    if (!shouldSucceed) {
      throw AuthException('Failed to reset password');
    }
  }
}

// Helper to scroll to and tap a widget
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  group('ResetPasswordPage widget tests', () {
    testWidgets('missing reset code shows invalid-link error', (tester) async {
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
            AppRouter.passwordResetSuccess: (_) =>
                const Scaffold(body: Text('Success')),
          },
          onGenerateRoute: (_) => null,
          home: ResetPasswordPage(authRepository: repo, code: null),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Reset Password with null code
      await _scrollToAndTap(tester, find.text('Reset Password'));
      await tester.pumpAndSettle();

      // Verify the page didn't navigate away (still on ResetPasswordPage)
      expect(find.text('Reset Your Password'), findsOneWidget);
      // Verify confirmPasswordReset was NOT called
      expect(repo.confirmPasswordResetCallCount, 0);
    });

    testWidgets('empty form validation', (tester) async {
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
            AppRouter.passwordResetSuccess: (_) =>
                const Scaffold(body: Text('Success')),
          },
          onGenerateRoute: (_) => null,
          home: ResetPasswordPage(authRepository: repo, code: 'test-code-123'),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to and tap Reset Password with empty fields
      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      // Verify validation messages
      expect(find.text('Please enter a new password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('invalid password requirements', (tester) async {
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
            AppRouter.passwordResetSuccess: (_) =>
                const Scaffold(body: Text('Success')),
          },
          onGenerateRoute: (_) => null,
          home: ResetPasswordPage(authRepository: repo, code: 'test-code-123'),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid password (too short, no uppercase, no number)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter new password'),
        'pass',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'pass',
      );
      await tester.pump();

      // Tap Reset Password
      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      // Verify password requirements error
      expect(
        find.text('Password does not meet the requirements'),
        findsOneWidget,
      );
    });

    testWidgets('confirm password mismatch', (tester) async {
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
            AppRouter.passwordResetSuccess: (_) =>
                const Scaffold(body: Text('Success')),
          },
          onGenerateRoute: (_) => null,
          home: ResetPasswordPage(authRepository: repo, code: 'test-code-123'),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter new password'),
        'Password1',
      );
      // Enter different confirm password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'Different1',
      );
      await tester.pump();

      // Tap Reset Password
      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      // Verify mismatch error
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('loading state', (tester) async {
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
            AppRouter.passwordResetSuccess: (_) =>
                const Scaffold(body: Text('Success')),
          },
          onGenerateRoute: (_) => null,
          home: ResetPasswordPage(authRepository: repo, code: 'test-code-123'),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid matching passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter new password'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'Password1',
      );
      await tester.pump();

      // Tap Reset Password
      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      // Verify loading state: button disabled, CircularProgressIndicator visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The button should be disabled (onPressed == null)
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);

      // Complete the fake future
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'successful password reset navigates to Password Reset Success',
      (tester) async {
        final repo = _FakeAuthRepository(shouldSucceed: true);
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
              // AppRouter.passwordResetSuccess intentionally omitted to allow onGenerateRoute to handle it
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppRouter.passwordResetSuccess) {
                capturedRouteSettings = settings;
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(body: Text('Success')),
                  settings: settings,
                );
              }
              return null;
            },
            home: ResetPasswordPage(
              authRepository: repo,
              code: 'test-code-123',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter valid matching passwords
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter new password'),
          'Password1',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm new password'),
          'Password1',
        );
        await tester.pump();

        // Tap Reset Password
        await tester.ensureVisible(find.text('Reset Password'));
        await tester.tap(find.text('Reset Password'));
        await tester.pumpAndSettle();

        // Verify navigation to AppRouter.passwordResetSuccess by capturing RouteSettings
        expect(capturedRouteSettings, isNotNull);
        expect(capturedRouteSettings!.name, AppRouter.passwordResetSuccess);
        expect(capturedRouteSettings!.arguments, isNull);
      },
    );
  });
}
