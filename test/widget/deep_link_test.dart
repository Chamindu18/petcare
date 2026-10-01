import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/core/services/deep_link_service.dart';
import 'package:petcare/main.dart';

class _FakeDeepLinkService implements DeepLinkService {
  _FakeDeepLinkService({this.initialUri});

  final Uri? initialUri;
  ValueChanged<Uri>? onLink;
  int startCallCount = 0;
  bool disposed = false;

  @override
  Future<Uri?> start({required ValueChanged<Uri> onLink}) async {
    startCallCount++;
    this.onLink = onLink;
    return initialUri;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _RouteCapture {
  RouteSettings? settings;
}

class _MockFirebaseCorePlatform extends FirebasePlatform {
  _MockFirebaseCorePlatform();

  final _MockFirebaseAppPlatform _defaultApp = _MockFirebaseAppPlatform(
    name: '[DEFAULT]',
    options: const FirebaseOptions(
      apiKey: 'mock-api-key',
      appId: 'mock-app-id',
      messagingSenderId: 'mock-sender-id',
      projectId: 'mock-project-id',
    ),
  );

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (name == defaultFirebaseAppName) {
      return _defaultApp;
    }
    throw StateError('App $name not found');
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
    FirebaseAppPlatform? existingApp,
  }) async {
    return _MockFirebaseAppPlatform(
      name: name ?? 'mock-app',
      options:
          options ??
          const FirebaseOptions(
            apiKey: 'mock-api-key',
            appId: 'mock-app-id',
            messagingSenderId: 'mock-sender-id',
            projectId: 'mock-project-id',
          ),
    );
  }

  Future<void> initializeCore() async {}
}

class _MockFirebaseAppPlatform extends FirebaseAppPlatform {
  _MockFirebaseAppPlatform({
    required String name,
    required FirebaseOptions options,
  }) : super(name, options);

  @override
  Future<void> delete() async {}

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  String get name => 'mock-app';

  @override
  FirebaseOptions get options => const FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: 'mock-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
  );
}

void setupFirebaseCoreMocks() {
  FirebasePlatform.instance = _MockFirebaseCorePlatform();
}

class _DelayedDeepLinkService implements DeepLinkService {
  _DelayedDeepLinkService({required this.uri});

  final Uri uri;
  ValueChanged<Uri>? _onLink;

  @override
  Future<Uri?> start({required ValueChanged<Uri> onLink}) async {
    _onLink = onLink;
    return null;
  }

  void deliverLink() {
    if (_onLink != null) {
      _onLink!(uri);
    }
  }

  @override
  Future<void> dispose() async {}
}

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupFirebaseCoreMocks();
  });

  group('Password reset deep-link handling', () {
    late _RouteCapture routeCapture;

    Map<String, WidgetBuilder> buildTestRoutes() {
      final routes = Map<String, WidgetBuilder>.from(AppRouter.routes);
      routes.remove(AppRouter.resetPassword); // Force through onGenerateRoute
      return routes;
    }

    Widget buildTestApp({required DeepLinkService deepLinkService}) {
      return PetCareApp(
        deepLinkService: deepLinkService,
        navigatorKey: _navigatorKey,
        routes: buildTestRoutes(),
        onGenerateRoute: (settings) {
          if (settings.name == AppRouter.resetPassword) {
            routeCapture.settings = settings;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Reset Password')),
              settings: settings,
            );
          }
          return AppRouter.routeGenerator()(settings);
        },
      );
    }

    setUp(() {
      routeCapture = _RouteCapture();
    });

    testWidgets(
      'valid password-reset deep link navigates to resetPassword with correct oobCode',
      (tester) async {
        const testCode = 'TEST_CODE_123';
        const outerHost = 'petcare-d4413.firebaseapp.com';
        const outerPath = '/__/auth/links';
        const innerPath = '/__/auth/action';
        final innerUri = Uri(
          scheme: 'https',
          host: outerHost,
          path: innerPath,
          queryParameters: {'mode': 'resetPassword', 'oobCode': testCode},
        );
        final outerUri = Uri(
          scheme: 'https',
          host: outerHost,
          path: outerPath,
          queryParameters: {'link': innerUri.toString()},
        );

        final fakeDeepLinkService = _FakeDeepLinkService(initialUri: outerUri);

        await tester.pumpWidget(
          buildTestApp(deepLinkService: fakeDeepLinkService),
        );
        await tester.pumpAndSettle();

        expect(routeCapture.settings, isNotNull);
        expect(routeCapture.settings!.name, AppRouter.resetPassword);
        expect(routeCapture.settings!.arguments, testCode);
      },
    );

    testWidgets('invalid outer host/path rejected', (tester) async {
      const testCode = 'TEST_CODE_123';
      final innerUri = Uri(
        scheme: 'https',
        host: 'petcare-d4413.firebaseapp.com',
        path: '/__/auth/action',
        queryParameters: {'mode': 'resetPassword', 'oobCode': testCode},
      );
      final outerUri = Uri(
        scheme: 'https',
        host: 'wrong-host.firebaseapp.com',
        path: '/__/auth/links',
        queryParameters: {'link': innerUri.toString()},
      );

      final fakeDeepLinkService = _FakeDeepLinkService(initialUri: outerUri);

      await tester.pumpWidget(
        buildTestApp(deepLinkService: fakeDeepLinkService),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('invalid inner host/path rejected', (tester) async {
      const testCode = 'TEST_CODE_123';
      final innerUri = Uri(
        scheme: 'https',
        host: 'wrong-host.firebaseapp.com',
        path: '/__/auth/action',
        queryParameters: {'mode': 'resetPassword', 'oobCode': testCode},
      );
      final outerUri = Uri(
        scheme: 'https',
        host: 'petcare-d4413.firebaseapp.com',
        path: '/__/auth/links',
        queryParameters: {'link': innerUri.toString()},
      );

      final fakeDeepLinkService = _FakeDeepLinkService(initialUri: outerUri);

      await tester.pumpWidget(
        buildTestApp(deepLinkService: fakeDeepLinkService),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('non-resetPassword mode rejected', (tester) async {
      const testCode = 'TEST_CODE_123';
      final innerUri = Uri(
        scheme: 'https',
        host: 'petcare-d4413.firebaseapp.com',
        path: '/__/auth/action',
        queryParameters: {'mode': 'verifyEmail', 'oobCode': testCode},
      );
      final outerUri = Uri(
        scheme: 'https',
        host: 'petcare-d4413.firebaseapp.com',
        path: '/__/auth/links',
        queryParameters: {'link': innerUri.toString()},
      );

      final fakeDeepLinkService = _FakeDeepLinkService(initialUri: outerUri);

      await tester.pumpWidget(
        buildTestApp(deepLinkService: fakeDeepLinkService),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('missing or blank oobCode rejected', (tester) async {
      final innerUriMissing = Uri(
        scheme: 'https',
        host: 'petcare-d4413.firebaseapp.com',
        path: '/__/auth/action',
        queryParameters: {'mode': 'resetPassword'},
      );
      final outerUriMissing = Uri(
        scheme: 'https',
        host: 'petcare-d4413.firebaseapp.com',
        path: '/__/auth/links',
        queryParameters: {'link': innerUriMissing.toString()},
      );

      final fakeDeepLinkService = _FakeDeepLinkService(
        initialUri: outerUriMissing,
      );

      await tester.pumpWidget(
        buildTestApp(deepLinkService: fakeDeepLinkService),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);

      final innerUriBlank = Uri(
        scheme: 'https',
        host: 'petcare-d4413.firebaseapp.com',
        path: '/__/auth/action',
        queryParameters: {'mode': 'resetPassword', 'oobCode': '   '},
      );
      final outerUriBlank = Uri(
        scheme: 'https',
        host: 'petcare-d4413.firebaseapp.com',
        path: '/__/auth/links',
        queryParameters: {'link': innerUriBlank.toString()},
      );

      final fakeDeepLinkService2 = _FakeDeepLinkService(
        initialUri: outerUriBlank,
      );

      await tester.pumpWidget(
        buildTestApp(deepLinkService: fakeDeepLinkService2),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('duplicate deep link ignored', (tester) async {
      const testCode = 'TEST_CODE_123';
      const outerHost = 'petcare-d4413.firebaseapp.com';
      const outerPath = '/__/auth/links';
      const innerPath = '/__/auth/action';
      final innerUri = Uri(
        scheme: 'https',
        host: outerHost,
        path: innerPath,
        queryParameters: {'mode': 'resetPassword', 'oobCode': testCode},
      );
      final outerUri = Uri(
        scheme: 'https',
        host: outerHost,
        path: outerPath,
        queryParameters: {'link': innerUri.toString()},
      );

      final fakeDeepLinkService = _FakeDeepLinkService(initialUri: outerUri);

      await tester.pumpWidget(
        buildTestApp(deepLinkService: fakeDeepLinkService),
      );
      await tester.pumpAndSettle();

      expect(routeCapture.settings, isNotNull);
      expect(routeCapture.settings!.arguments, testCode);
      final firstNavigationCode = routeCapture.settings!.arguments;

      if (fakeDeepLinkService.onLink != null) {
        fakeDeepLinkService.onLink!(outerUri);
        await tester.pumpAndSettle();
      }

      expect(routeCapture.settings, isNotNull);
      expect(routeCapture.settings!.arguments, firstNavigationCode);
    });

    testWidgets('pending deep link before navigator is ready', (tester) async {
      const testCode = 'PENDING_TEST_CODE';
      const outerHost = 'petcare-d4413.firebaseapp.com';
      const outerPath = '/__/auth/links';
      const innerPath = '/__/auth/action';
      final innerUri = Uri(
        scheme: 'https',
        host: outerHost,
        path: innerPath,
        queryParameters: {'mode': 'resetPassword', 'oobCode': testCode},
      );
      final outerUri = Uri(
        scheme: 'https',
        host: outerHost,
        path: outerPath,
        queryParameters: {'link': innerUri.toString()},
      );

      final delayedService = _DelayedDeepLinkService(uri: outerUri);

      await tester.pumpWidget(buildTestApp(deepLinkService: delayedService));

      delayedService.deliverLink();

      await tester.pumpAndSettle();

      expect(routeCapture.settings, isNotNull);
      expect(routeCapture.settings!.name, AppRouter.resetPassword);
      expect(routeCapture.settings!.arguments, testCode);
    });
  });
}
