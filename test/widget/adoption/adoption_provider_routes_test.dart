import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/auth/presentation/pages/login_page.dart';

class _BuildContextStub implements BuildContext {
  const _BuildContextStub();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const providerRoutes = [
    AppRouter.adoptionProviderDashboard,
    AppRouter.adoptionRequests,
    AppRouter.myAdoptionListings,
    AppRouter.createEditAdoptionListing,
  ];

  test('redirects signed-out users from provider routes to login', () {
    final auth = MockFirebaseAuth(signedIn: false);
    final routeGenerator = AppRouter.routeGenerator(auth: auth);

    for (final routeName in providerRoutes) {
      final route = routeGenerator(RouteSettings(name: routeName));

      expect(route, isA<MaterialPageRoute>(), reason: routeName);

      final materialRoute = route! as MaterialPageRoute;
      expect(materialRoute.settings.name, routeName);

      final page = materialRoute.builder(const _BuildContextStub());
      expect(page, isA<LoginPage>(), reason: routeName);
    }
  });

  test('registers provider routes for authenticated users', () {
    final auth = MockFirebaseAuth(signedIn: true);
    final routeGenerator = AppRouter.routeGenerator(auth: auth);

    for (final routeName in providerRoutes) {
      final route = routeGenerator(RouteSettings(name: routeName));

      expect(route, isA<MaterialPageRoute>(), reason: routeName);
      expect(route!.settings.name, routeName);
    }
  });
}
