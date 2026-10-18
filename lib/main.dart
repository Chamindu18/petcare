import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/services/deep_link_service.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PetCareApp());
}

class PetCareApp extends StatefulWidget {
  const PetCareApp({
    super.key,
    this.deepLinkService,
    this.navigatorKey,
    this.onGenerateRoute,
    this.routes,
    this.auth,
  });

  final DeepLinkService? deepLinkService;
  final GlobalKey<NavigatorState>? navigatorKey;
  final RouteFactory? onGenerateRoute;
  final Map<String, WidgetBuilder>? routes;
  final FirebaseAuth? auth;

  @override
  State<PetCareApp> createState() => _PetCareAppState();
}

class _PetCareAppState extends State<PetCareApp> {
  late final GlobalKey<NavigatorState> _navigatorKey;

  late final DeepLinkService _deepLinkService;

  String? _lastHandledLink;
  Uri? _pendingDeepLink;
  Completer<bool>? _startupCompleter;

  @override
  void initState() {
    super.initState();

    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();

    _deepLinkService = widget.deepLinkService ?? DeepLinkService();

    // Start listening as early as possible so cold-start
    // links can be captured by app_links.
    _initializeDeepLinks();
  }

  Future<void> _initializeDeepLinks() async {
    _startupCompleter = Completer<bool>();
    Uri? initialUri;

    try {
      initialUri = await _deepLinkService.start(onLink: _handleDeepLink);
    } catch (_) {
      // If initial-link initialization fails, complete the startup
      // decision with false so normal authentication-based startup continues.
      if (!_startupCompleter!.isCompleted) {
        _startupCompleter!.complete(false);
      }
      return;
    }

    if (!mounted || initialUri == null) {
      if (!_startupCompleter!.isCompleted) {
        _startupCompleter!.complete(false);
      }
      return;
    }

    // Wait until MaterialApp and Navigator are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      // Handle the deep link. This function completes the startup completer
      // immediately but keeps awaiting the route-result future to ensure
      // pumpAndSettle continues pumping frames for the transition animation.
      // initialUri is non-null here due to the check above.
      final handled = await _handleDeepLink(initialUri!);
      if (!_startupCompleter!.isCompleted) {
        _startupCompleter!.complete(handled);
      }
    });
  }

  /// Handles a deep link URI.
  ///
  /// Returns `true` if a password-reset navigation was initiated.
  /// Completes the startup completer immediately but continues awaiting
  /// the route-result future in the background to keep pumpAndSettle
  /// pumping frames for the transition animation.
  Future<bool> _handleDeepLink(Uri uri) async {
    const firebaseAuthHost = 'petcare-d4413.firebaseapp.com';
    const firebaseAuthOuterPath = '/__/auth/links';
    const firebaseAuthActionPath = '/__/auth/action';

    // Only handle links from our Firebase Auth domain (outer URI).
    if (uri.host != firebaseAuthHost) {
      return false;
    }

    // Only handle the outer Firebase Hosting App Link path.
    if (uri.path != firebaseAuthOuterPath) {
      return false;
    }

    // Read the nested action link from the 'link' query parameter.
    final innerLink = uri.queryParameters['link'];

    if (innerLink == null || innerLink.isEmpty) {
      return false;
    }

    // Parse the inner Firebase Auth action URI.
    final innerUri = Uri.tryParse(innerLink);

    if (innerUri == null) {
      return false;
    }

    // Validate inner URI host and path.
    if (innerUri.host != firebaseAuthHost) {
      return false;
    }

    if (innerUri.path != firebaseAuthActionPath) {
      return false;
    }

    // Only handle password-reset links.
    if (innerUri.queryParameters['mode'] != 'resetPassword') {
      return false;
    }

    final code = innerUri.queryParameters['oobCode']?.trim();

    if (code == null || code.isEmpty) {
      return false;
    }

    final link = uri.toString();

    // Prevent handling the same link more than once.
    if (_lastHandledLink == link) {
      return false;
    }

    final navigator = _navigatorKey.currentState;

    // Android can deliver the link before the Navigator is ready.
    // Store it and process it once Flutter has built the UI.
    if (navigator == null) {
      _pendingDeepLink = uri;

      final completer = Completer<bool>();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _pendingDeepLink == null) {
          completer.complete(false);
          return;
        }

        final pendingUri = _pendingDeepLink;
        _pendingDeepLink = null;

        if (pendingUri != null) {
          final handled = await _handleDeepLink(pendingUri);
          completer.complete(handled);
        } else {
          completer.complete(false);
        }
      });

      return completer.future;
    }

    _lastHandledLink = link;

    // Replace the splash route so its timer cannot later navigate
    // the user to onboarding. Do NOT await the route-result future;
    // it completes when the new route is popped, not when the
    // transition finishes. The startup completer is completed by
    // the caller after this returns.
    unawaited(
      navigator.pushReplacementNamed(AppRouter.resetPassword, arguments: code),
    );

    return true;
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routes = Map<String, WidgetBuilder>.from(
      widget.routes ?? AppRouter.routes,
    );
    routes[AppRouter.splash] = (context) =>
        SplashPage(auth: widget.auth, startupFuture: _startupCompleter?.future);

    return MaterialApp(
      title: 'PetCare+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      initialRoute: AppRouter.splash,
      routes: routes,
      onGenerateRoute: widget.onGenerateRoute ?? AppRouter.routeGenerator(),
    );
  }
}
