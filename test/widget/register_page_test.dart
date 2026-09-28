import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';
import 'package:petcare/features/auth/presentation/pages/register_page.dart';

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
}

void main() {
  group('RegisterPage widget tests', () {
    // Helper to create a test app with RegisterPage
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
        },
        onGenerateRoute: onGenerateRoute,
        home: RegisterPage(authRepository: repo),
      );
    }

    // Helper to scroll to and tap a widget
    Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }

    testWidgets('empty form validation', (tester) async {
      final repo = _FakeAuthRepository();

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Scroll to and tap Create Account button with empty fields
      await scrollToAndTap(tester, find.text('Create Account'));

      // Verify validation messages
      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
      expect(find.text('Please create a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('invalid email validation', (tester) async {
      final repo = _FakeAuthRepository();

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Enter valid full name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'John Doe',
      );
      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'not-an-email',
      );
      // Enter valid phone number
      await tester.enterText(
        find.widgetWithText(TextFormField, '+94 77 123 4567'),
        '+94 77 123 4567',
      );
      // Enter valid password (8+ chars, uppercase, number)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'Password1',
      );
      // Enter matching confirm password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm your password'),
        'Password1',
      );
      await tester.pump();

      // Scroll to and tap Create Account
      await scrollToAndTap(tester, find.text('Create Account'));

      // Verify email format error
      expect(find.text('Please enter a valid email'), findsOneWidget);
      // Other fields should be valid (no errors)
      expect(find.text('Please enter a valid phone number'), findsNothing);
      expect(
        find.text('Password does not meet the requirements'),
        findsNothing,
      );
      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('invalid phone validation', (tester) async {
      final repo = _FakeAuthRepository();

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Enter valid full name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'John Doe',
      );
      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'john@example.com',
      );
      // Enter invalid phone (too few digits)
      await tester.enterText(
        find.widgetWithText(TextFormField, '+94 77 123 4567'),
        '123',
      );
      // Enter valid password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'Password1',
      );
      // Enter matching confirm password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm your password'),
        'Password1',
      );
      await tester.pump();

      // Scroll to and tap Create Account
      await scrollToAndTap(tester, find.text('Create Account'));

      // Verify phone validation error
      expect(find.text('Please enter a valid phone number'), findsOneWidget);
      // Other fields should be valid
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(
        find.text('Password does not meet the requirements'),
        findsNothing,
      );
    });

    testWidgets('invalid password requirements', (tester) async {
      final repo = _FakeAuthRepository();

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Enter valid full name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'John Doe',
      );
      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'john@example.com',
      );
      // Enter valid phone
      await tester.enterText(
        find.widgetWithText(TextFormField, '+94 77 123 4567'),
        '+94 77 123 4567',
      );
      // Enter invalid password (too short, no uppercase, no number)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'pass',
      );
      // Enter matching confirm password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm your password'),
        'pass',
      );
      await tester.pump();

      // Scroll to and tap Create Account
      await scrollToAndTap(tester, find.text('Create Account'));

      // Verify password validation error
      expect(
        find.text('Password does not meet the requirements'),
        findsOneWidget,
      );
      // Other fields should be valid
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(find.text('Please enter a valid phone number'), findsNothing);
    });

    testWidgets('confirm-password mismatch', (tester) async {
      final repo = _FakeAuthRepository();

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Enter valid full name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'John Doe',
      );
      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'john@example.com',
      );
      // Enter valid phone
      await tester.enterText(
        find.widgetWithText(TextFormField, '+94 77 123 4567'),
        '+94 77 123 4567',
      );
      // Enter valid password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'Password1',
      );
      // Enter different confirm password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm your password'),
        'Different1',
      );
      await tester.pump();

      // Scroll to and tap Create Account
      await scrollToAndTap(tester, find.text('Create Account'));

      // Verify confirm password mismatch error
      expect(find.text('Passwords do not match'), findsOneWidget);
      // Other fields should be valid
      expect(
        find.text('Password does not meet the requirements'),
        findsNothing,
      );
    });

    testWidgets('registration loading state', (tester) async {
      final completer = Completer<void>();
      final repo = _FakeAuthRepository(
        shouldSucceed: true,
        delayFuture: completer.future,
      );

      await tester.pumpWidget(
        createTestApp(repo: repo, onGenerateRoute: (_) => null),
      );

      // Fill all fields with valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '+94 77 123 4567'),
        '+94 77 123 4567',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm your password'),
        'Password1',
      );
      await tester.pump();

      // Scroll to and tap Create Account
      await scrollToAndTap(tester, find.text('Create Account'));

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

    testWidgets('successful registration navigates to Home', (tester) async {
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
          home: RegisterPage(authRepository: repo),
        ),
      );

      // Fill all fields with valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '+94 77 123 4567'),
        '+94 77 123 4567',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'Password1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm your password'),
        'Password1',
      );
      await tester.pump();

      // Scroll to and tap Create Account
      await scrollToAndTap(tester, find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify navigation to AppRouter.home by capturing RouteSettings
      expect(capturedRouteSettings, isNotNull);
      expect(capturedRouteSettings!.name, AppRouter.home);
      expect(capturedRouteSettings!.arguments, isNull);
    });
  });
}
