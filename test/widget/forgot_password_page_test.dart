import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/auth/presentation/pages/forgot_password_page.dart';

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

  @override
  Future<void> signOut() async {}
}

void main() {
  group('ForgotPasswordPage widget tests', () {
    // Helper to create a test app with ForgotPasswordPage
    Widget createTestApp({
      required AuthRepository repo,
      RouteFactory? onGenerateRoute,
    }) {
      return MaterialApp(
        routes: {
          AppRouter.login: (_) => const Scaffold(body: Text('Login')),
          AppRouter.register: (_) => const Scaffold(body: Text('Register')),
          AppRouter.forgotPassword: (_) =>
              const Scaffold(body: Text('Forgot Password')),
          AppRouter.onboarding: (_) => const Scaffold(body: Text('Onboarding')),
          AppRouter.checkEmail: (_) =>
              const Scaffold(body: Text('Check Email')),
        },
        onGenerateRoute: onGenerateRoute,
        home: ForgotPasswordPage(authRepository: repo),
      );
    }

    testWidgets('empty email validation', (tester) async {
      final repo = _FakeAuthRepository();

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Tap "Send Reset Link" with empty email field
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      // Verify validation message
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('invalid email validation', (tester) async {
      final repo = _FakeAuthRepository();

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your email address'),
        'not-an-email',
      );
      await tester.pump();

      // Tap Send Reset Link
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      // Verify email format error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('loading state', (tester) async {
      final completer = Completer<void>();
      final repo = _FakeAuthRepository(
        shouldSucceed: true,
        delayFuture: completer.future,
      );

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your email address'),
        'test@example.com',
      );
      await tester.pump();

      // Tap Send Reset Link
      await tester.tap(find.text('Send Reset Link'));
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

    testWidgets('successful reset navigates to Check Email', (tester) async {
      final repo = _FakeAuthRepository(shouldSucceed: true);
      RouteSettings? capturedRouteSettings;
      const testEmail = 'test@example.com';

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRouter.login: (_) => const Scaffold(body: Text('Login')),
            AppRouter.register: (_) => const Scaffold(body: Text('Register')),
            AppRouter.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
            AppRouter.onboarding: (_) =>
                const Scaffold(body: Text('Onboarding')),
            // AppRouter.checkEmail intentionally omitted to allow onGenerateRoute to handle it
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.checkEmail) {
              capturedRouteSettings = settings;
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Check Email')),
                settings: settings,
              );
            }
            return null;
          },
          home: ForgotPasswordPage(authRepository: repo),
        ),
      );

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your email address'),
        testEmail,
      );
      await tester.pump();

      // Tap Send Reset Link
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Verify navigation to Check Email by capturing RouteSettings
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.checkEmail);
      expect(capturedRouteSettings!.arguments, testEmail);
    });

    testWidgets('bottom artwork hides when keyboard is visible', (
      tester,
    ) async {
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
          home: ForgotPasswordPage(authRepository: repo),
        ),
      );

      // Initially keyboard is hidden - artwork should be present
      expect(
        find.bySemanticsLabel('Golden retriever and cat together'),
        findsOneWidget,
      );

      // Simulate keyboard open by pumping with viewInsets
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQuery.of(tester.element(find.byType(Scaffold)))
              .copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
          child: MaterialApp(
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
            home: ForgotPasswordPage(authRepository: repo),
          ),
        ),
      );

      // Artwork should be hidden when keyboard is visible
      expect(
        find.bySemanticsLabel('Golden retriever and cat together'),
        findsNothing,
      );
    });

    testWidgets('bottom artwork shows when keyboard is hidden', (tester) async {
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
          home: ForgotPasswordPage(authRepository: repo),
        ),
      );

      // Keyboard hidden - artwork should be present
      expect(
        find.bySemanticsLabel('Golden retriever and cat together'),
        findsOneWidget,
      );

      // Simulate keyboard dismissed
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
          home: ForgotPasswordPage(authRepository: repo),
        ),
      );

      // Artwork should be present after keyboard dismissed
      expect(
        find.bySemanticsLabel('Golden retriever and cat together'),
        findsOneWidget,
      );
    });
  });
}
