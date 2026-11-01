import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/router/adoption_provider_access_gate.dart';
import 'package:petcare/app/router/adoption_workspace_access_gate.dart';
import 'package:petcare/features/adoption/presentation/pages/adoption_listings_page.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/presentation/pages/login_page.dart';

class _BuildContextStub implements BuildContext {
  const _BuildContextStub();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const protectedAdoptionRoutes = [
    AppRouter.adoptionListings,
    AppRouter.adoptionProviderDashboard,
    AppRouter.adoptionRequests,
    AppRouter.myAdoptionListings,
    AppRouter.createEditAdoptionListing,
    AppRouter.ownerRehomingDashboard,
    AppRouter.myAdoptionRequests,
  ];

  test(
    'redirects signed-out users from protected adoption routes to login',
    () {
      final auth = MockFirebaseAuth(signedIn: false);
      final routeGenerator = AppRouter.routeGenerator(auth: auth);

      for (final routeName in protectedAdoptionRoutes) {
        final route = routeGenerator(RouteSettings(name: routeName));

        expect(route, isA<MaterialPageRoute>(), reason: routeName);

        final materialRoute = route! as MaterialPageRoute;
        expect(materialRoute.settings.name, routeName);

        final page = materialRoute.builder(const _BuildContextStub());
        expect(page, isA<LoginPage>(), reason: routeName);
      }
    },
  );

  test('registers protected adoption routes for authenticated users', () {
    final auth = MockFirebaseAuth(signedIn: true);
    final routeGenerator = AppRouter.routeGenerator(auth: auth);

    for (final routeName in protectedAdoptionRoutes) {
      final route = routeGenerator(RouteSettings(name: routeName));

      expect(route, isA<MaterialPageRoute>(), reason: routeName);
      expect(route!.settings.name, routeName);
    }
  });

  test('restricts advertisement management routes to providers', () {
    final auth = MockFirebaseAuth(signedIn: true);
    final routeGenerator = AppRouter.routeGenerator(auth: auth);

    const providerOnlyRoutes = [
      AppRouter.myAdoptionListings,
      AppRouter.adoptionRequests,
      AppRouter.createEditAdoptionListing,
    ];

    for (final routeName in providerOnlyRoutes) {
      final route = routeGenerator(RouteSettings(name: routeName));
      expect(route, isA<MaterialPageRoute>(), reason: routeName);

      final page = (route! as MaterialPageRoute).builder(
        const _BuildContextStub(),
      );

      expect(page, isA<AdoptionWorkspaceAccessGate>(), reason: routeName);
      expect((page as AdoptionWorkspaceAccessGate).allowedRoles, {
        'adoption_provider',
      }, reason: routeName);
    }

    final dashboardRoute = routeGenerator(
      const RouteSettings(name: AppRouter.adoptionProviderDashboard),
    );

    final dashboardPage = (dashboardRoute! as MaterialPageRoute).builder(
      const _BuildContextStub(),
    );

    expect(dashboardPage, isA<AdoptionProviderAccessGate>());
  });

  test('keeps public adoption listings available to signed-in owners', () {
    final auth = MockFirebaseAuth(signedIn: true);
    final routeGenerator = AppRouter.routeGenerator(auth: auth);

    final route = routeGenerator(
      const RouteSettings(name: AppRouter.adoptionListings),
    );

    expect(route, isA<MaterialPageRoute>());

    final page = (route! as MaterialPageRoute).builder(
      const _BuildContextStub(),
    );

    expect(page, isA<AdoptionListingsPage>());
  });

  test('keeps submitted adoption request history available to owners', () {
    final auth = MockFirebaseAuth(signedIn: true);
    final routeGenerator = AppRouter.routeGenerator(auth: auth);

    final route = routeGenerator(
      const RouteSettings(name: AppRouter.myAdoptionRequests),
    );

    expect(route, isA<MaterialPageRoute>());

    final page = (route! as MaterialPageRoute).builder(
      const _BuildContextStub(),
    );

    expect(page, isA<AdoptionWorkspaceAccessGate>());
    expect((page as AdoptionWorkspaceAccessGate).allowedRoles, {'owner'});
  });
}
