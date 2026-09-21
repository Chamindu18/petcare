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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinks();
    });
  }

  Future<void> _initializeDeepLinks() async {
    final initialUri = await _deepLinkService.start(onLink: _handleDeepLink);

    if (!mounted || initialUri == null) {
      return;
    }

    _handleDeepLink(initialUri);
  }

  void _handleDeepLink(Uri uri) {
    const firebaseAuthHost = 'petcare-d4413.firebaseapp.com';
    const firebaseAuthPath = '/__/auth/links';

    if (uri.host != firebaseAuthHost) {
      return;
    }

    if (uri.path != firebaseAuthPath) {
      return;
    }

    if (uri.queryParameters['mode'] != 'resetPassword') {
      return;
    }

    final code = uri.queryParameters['oobCode']?.trim();

    if (code == null || code.isEmpty) {
      return;
    }

    final link = uri.toString();

    if (_lastHandledLink == link) {
      return;
    }

    _lastHandledLink = link;

    final navigator = _navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    navigator.pushNamed(AppRouter.resetPassword, arguments: code);
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
