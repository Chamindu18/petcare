import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/auth/presentation/pages/login_page.dart';

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
    if (!shouldSucceed) {
      throw AuthException('Registration failed');
    }
  }

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (delayFuture != null) {
      await delayFuture!;
    }
    if (!shouldSucceed) {
      throw AuthException('Login failed');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    if (delayFuture != null) {
      await delayFuture!;
    }
    if (!shouldSucceed) {
      throw AuthException('Google sign in failed');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  group('LoginPage widget tests', () {
    testWidgets('empty form shows validation errors', (tester) async {
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
          },
          onGenerateRoute: (_) => null,
          home: LoginPage(authRepository: repo),
        ),
      );

      // Tap Log In button with empty fields
      await tester.tap(find.text('Log In'));
      await tester.pump();

      // Verify validation messages
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('invalid email shows format error', (tester) async {
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
          },
          onGenerateRoute: (_) => null,
          home: LoginPage(authRepository: repo),
        ),
      );

      // Enter invalid email and valid password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'not-an-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'validpass',
      );
      await tester.pump();

      // Tap Log In
      await tester.tap(find.text('Log In'));
      await tester.pump();

      // Verify email format error
      expect(find.text('Please enter a valid email'), findsOneWidget);
      // Password should be valid (no error)
      expect(find.text('Please enter your password'), findsNothing);
    });

    testWidgets('short password shows length error', (tester) async {
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
          },
          onGenerateRoute: (_) => null,
          home: LoginPage(authRepository: repo),
        ),
      );

      // Enter valid email and short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        '123',
      );
      await tester.pump();

      // Tap Log In
      await tester.tap(find.text('Log In'));
      await tester.pump();

      // Verify password length error
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
      // Email should be valid (no error)
      expect(find.text('Please enter a valid email'), findsNothing);
    });

    testWidgets(
      'login loading state shows progress indicator and disables button',
      (tester) async {
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
            },
            onGenerateRoute: (_) => null,
            home: LoginPage(authRepository: repo),
          ),
        );

        // Enter valid credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'your@email.com'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your password'),
          'password123',
        );
        await tester.pump();

        // Tap Log In
        await tester.tap(find.text('Log In'));
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
      },
    );

    testWidgets('successful login navigates to Home', (tester) async {
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
            // AppRouter.home intentionally omitted to allow onGenerateRoute to handle it
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.home) {
              capturedRouteSettings = settings;
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Home')),
                settings: settings,
              );
            }
            return null;
          },
          home: LoginPage(authRepository: repo),
        ),
      );

      // Enter valid credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'password123',
      );
      await tester.pump();

      // Tap Log In
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.home by capturing RouteSettings
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.home);
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
          },
          onGenerateRoute: (_) => null,
          home: LoginPage(authRepository: repo),
        ),
      );

      // Initially keyboard is hidden - artwork should be present
      expect(
        find.bySemanticsLabel('PetCare+ dog and cat illustration'),
        findsOneWidget,
      );

      // Focus the email field to trigger keyboard (simulated via viewInsets)
      await tester.tap(find.widgetWithText(TextFormField, 'your@email.com'));
      await tester.pump();

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
            },
            onGenerateRoute: (_) => null,
            home: LoginPage(authRepository: repo),
          ),
        ),
      );

      // Artwork should be hidden when keyboard is visible
      expect(
        find.bySemanticsLabel('PetCare+ dog and cat illustration'),
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
          },
          onGenerateRoute: (_) => null,
          home: LoginPage(authRepository: repo),
        ),
      );

      // Keyboard hidden - artwork should be present
      expect(
        find.bySemanticsLabel('PetCare+ dog and cat illustration'),
        findsOneWidget,
      );

      // Focus and then unfocus (simulate keyboard dismissed)
      await tester.tap(find.widgetWithText(TextFormField, 'your@email.com'));
      await tester.pump();
      await tester.tap(find.byType(Scaffold)); // tap outside to dismiss
      await tester.pump();

      // Artwork should still be present after keyboard dismissed
      expect(
        find.bySemanticsLabel('PetCare+ dog and cat illustration'),
        findsOneWidget,
      );
    });
  });
}
