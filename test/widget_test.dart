import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage builds successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashPage()));

    expect(find.byType(SplashPage), findsOneWidget);
  });
}
