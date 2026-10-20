import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/app/router/owner_access_gate.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.role);

  final String? role;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    return Stream<UserProfile?>.value(
      role == null
          ? null
          : UserProfile(
              uid: 'test-user',
              fullName: 'Test User',
              displayName: 'Test User',
              email: 'test@example.com',
              phone: '0712345678',
              role: role!,
              notificationEnabled: true,
            ),
    );
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {}

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {}
}

const _ownerOnlyRoutes = <String>[
  AppRouter.myPets,
  AppRouter.addPet,
  AppRouter.petProfile,
  AppRouter.hospitalDiscovery,
  AppRouter.hospitalDetails,
  AppRouter.bookAppointment,
  AppRouter.appointmentConfirmation,
  AppRouter.aiHub,
  AppRouter.aiChat,
  AppRouter.healthSummary,
  AppRouter.preventiveInsights,
  AppRouter.vetVisitPreparation,
];

Future<void> _pumpGeneratedRoute(
  WidgetTester tester, {
  required String routeName,
  required String? role,
  Object? arguments,
}) async {
  final auth = MockFirebaseAuth(signedIn: true);
  final profileRepository = _FakeProfileRepository(role);
  final navigatorKey = GlobalKey<NavigatorState>();

  final routeGenerator = AppRouter.routeGenerator(
    auth: auth,
    profileRepository: profileRepository,
  );

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('Route launcher')),
    ),
  );

  final route = routeGenerator(
    RouteSettings(name: routeName, arguments: arguments),
  );

  expect(route, isNotNull, reason: 'Expected route $routeName to exist.');

  navigatorKey.currentState!.push(route!);
  await tester.pumpAndSettle();
}

void main() {
  group('AppRouter owner route authorization', () {
    final nonOwnerRoles = <MapEntry<String, String?>>[
      const MapEntry('veterinarian', 'veterinarian'),
      const MapEntry('veterinary staff', 'veterinary_staff'),
      const MapEntry('adoption provider', 'adoption_provider'),
      const MapEntry('unknown role', 'admin'),
      const MapEntry('empty role', ''),
      const MapEntry('missing profile', null),
    ];

    for (final entry in nonOwnerRoles) {
      testWidgets(
        'denies ${entry.key} access to the AI Hub through the router',
        (tester) async {
          await _pumpGeneratedRoute(
            tester,
            routeName: AppRouter.aiHub,
            role: entry.value,
          );

          expect(find.text('Owner access required'), findsOneWidget);
          expect(find.byType(OwnerAccessGate), findsOneWidget);
        },
      );
    }

    testWidgets('blocks an adoption provider on every owner-only route', (
      tester,
    ) async {
      for (final routeName in _ownerOnlyRoutes) {
        await _pumpGeneratedRoute(
          tester,
          routeName: routeName,
          role: 'adoption_provider',
        );

        expect(
          find.text('Owner access required'),
          findsOneWidget,
          reason: '$routeName should deny adoption-provider access.',
        );

        expect(
          find.byType(OwnerAccessGate),
          findsOneWidget,
          reason: '$routeName should be wrapped in OwnerAccessGate.',
        );
      }
    });

    testWidgets('preserves the route name and arguments on a guarded route', (
      tester,
    ) async {
      final auth = MockFirebaseAuth(signedIn: true);
      final profileRepository = _FakeProfileRepository('owner');

      final routeGenerator = AppRouter.routeGenerator(
        auth: auth,
        profileRepository: profileRepository,
      );

      const marker = 'test-route-argument';
      final route = routeGenerator(
        const RouteSettings(name: AppRouter.addPet, arguments: marker),
      );

      expect(route, isA<MaterialPageRoute<dynamic>>());
      expect(route!.settings.name, AppRouter.addPet);
      expect(route.settings.arguments, marker);
    });
  });
}
