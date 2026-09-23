import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/services/deep_link_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PetCareApp());
}

class PetCareApp extends StatefulWidget {
  const PetCareApp({super.key});

  @override
  State<PetCareApp> createState() => _PetCareAppState();
}

class _PetCareAppState extends State<PetCareApp> {
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  final DeepLinkService _deepLinkService = DeepLinkService();

  String? _lastHandledLink;
  Uri? _pendingDeepLink;

  @override
  void initState() {
    super.initState();

    // Start listening as early as possible so cold-start
    // links can be captured by app_links.
    _initializeDeepLinks();
  }

  Future<void> _initializeDeepLinks() async {
    final initialUri = await _deepLinkService.start(onLink: _handleDeepLink);

    if (!mounted || initialUri == null) {
      return;
    }

    // Wait until MaterialApp and Navigator are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _handleDeepLink(initialUri);
    });
  }

  void _handleDeepLink(Uri uri) {
    const firebaseAuthHost = 'petcare-d4413.firebaseapp.com';
    const firebaseAuthPath = '/__/auth/action';

    // Only handle links from our Firebase Auth domain.
    if (uri.host != firebaseAuthHost) {
      return;
    }

    // Only handle Firebase Authentication action links.
    if (uri.path != firebaseAuthPath) {
      return;
    }

    // Only handle password-reset links.
    if (uri.queryParameters['mode'] != 'resetPassword') {
      return;
    }

    final code = uri.queryParameters['oobCode']?.trim();

    if (code == null || code.isEmpty) {
      return;
    }

    final link = uri.toString();

    // Prevent handling the same link more than once.
    if (_lastHandledLink == link) {
      return;
    }

    final navigator = _navigatorKey.currentState;

    // Android can deliver the link before the Navigator is ready.
    // Store it and process it once Flutter has built the UI.
    if (navigator == null) {
      _pendingDeepLink = uri;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pendingDeepLink == null) {
          return;
        }

        final pendingUri = _pendingDeepLink;
        _pendingDeepLink = null;

        if (pendingUri != null) {
          _handleDeepLink(pendingUri);
        }
      });

      return;
    }

    _lastHandledLink = link;

    // Replace the splash route so its timer cannot later navigate
    // the user to onboarding.
    navigator.pushReplacementNamed(AppRouter.resetPassword, arguments: code);
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}
