import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/auth/presentation/pages/reset_password_page.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.shouldSucceed = true,
    this.delayFuture,
    this.resetErrorMessage,
  });

  final bool shouldSucceed;
  final Future<void>? delayFuture;
  final String? resetErrorMessage;

  // Track calls for verification.
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
      throw AuthException(resetErrorMessage ?? 'Failed to reset password');
    }
  }

  @override
  Future<void> signOut() async {}
}

// Helper to scroll to and tap a widget.
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

      // Tap Reset Password with a null reset code.
      await _scrollToAndTap(tester, find.text('Reset Password'));
      await tester.pumpAndSettle();

      // The page must remain visible.
      expect(find.text('Reset Your Password'), findsOneWidget);

      // The repository must not be called without a valid reset code.
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

      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      expect(find.text('Please enter a new password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
      expect(repo.confirmPasswordResetCallCount, 0);
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

      // Enter a password that does not meet the requirements.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter new password'),
        'pass',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'pass',
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      expect(
        find.text('Password does not meet the requirements'),
        findsOneWidget,
      );
      expect(repo.confirmPasswordResetCallCount, 0);
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

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter new password'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'Different1',
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(repo.confirmPasswordResetCallCount, 0);
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

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter new password'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'Password1',
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      // The page must show a loading indicator and disable the button.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);

      completer.complete();
      await tester.pumpAndSettle();
    });

    for (final errorMessage in <String>[
      'This password reset link has expired.',
      'This password reset link is invalid.',
    ]) {
      testWidgets('shows reset failure message: $errorMessage', (tester) async {
        final repo = _FakeAuthRepository(
          shouldSucceed: false,
          resetErrorMessage: errorMessage,
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
            home: ResetPasswordPage(
              authRepository: repo,
              code: 'test-code-123',
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter new password'),
          'Password1',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm new password'),
          'Password1',
        );
        await tester.pump();

        await tester.ensureVisible(find.text('Reset Password'));
        await tester.tap(find.text('Reset Password'));
        await tester.pumpAndSettle();

        // The error must be shown without navigating to success.
        expect(find.text(errorMessage), findsOneWidget);
        expect(repo.confirmPasswordResetCallCount, 1);
        expect(find.text('Success'), findsNothing);
        expect(find.text('Reset Your Password'), findsOneWidget);
      });
    }

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
              // Let onGenerateRoute handle the success route.
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

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter new password'),
          'Password1',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm new password'),
          'Password1',
        );
        await tester.pump();

        await tester.ensureVisible(find.text('Reset Password'));
        await tester.tap(find.text('Reset Password'));
        await tester.pumpAndSettle();

        expect(capturedRouteSettings, isNotNull);
        expect(capturedRouteSettings!.name, AppRouter.passwordResetSuccess);
        expect(capturedRouteSettings!.arguments, isNull);
        expect(repo.confirmPasswordResetCallCount, 1);
        expect(repo.lastResetCode, 'test-code-123');
        expect(repo.lastNewPassword, 'Password1');
      },
    );
  });
}
