import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/hospital_staff/presentation/pages/staff_hospital_overview_page.dart';
import 'package:petcare/features/hospitals/domain/entities/hospital.dart';
import 'package:petcare/features/hospitals/domain/repositories/hospital_repository.dart';

class _FakeHospitalRepository implements HospitalRepository {
  _FakeHospitalRepository(this._getHospital);

  final Future<Hospital?> Function(String hospitalId, int callNumber)
  _getHospital;

  int callCount = 0;
  final List<String> requestedHospitalIds = [];

  @override
  Future<Hospital?> getHospitalById(String hospitalId) {
    callCount++;
    requestedHospitalIds.add(hospitalId);
    return _getHospital(hospitalId, callCount);
  }

  @override
  Future<List<Hospital>> getHospitals() async => [];
}

Hospital _testHospital({
  bool active = true,
  String name = 'PetCare Animal Hospital',
}) {
  return Hospital(
    hospitalId: 'hospital-001',
    name: name,
    location: 'Colombo, Sri Lanka',
    contact: '0112345678',
    hours: 'Monday - Saturday, 8 AM - 6 PM',
    active: active,
  );
}

void main() {
  group('StaffHospitalOverviewPage', () {
    testWidgets('displays hospital details from the repository', (
      tester,
    ) async {
      final repository = _FakeHospitalRepository(
        (hospitalId, _) async => _testHospital(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffHospitalOverviewPage(
              hospitalId: 'hospital-001',
              repository: repository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PetCare Animal Hospital'), findsOneWidget);
      expect(find.text('Colombo, Sri Lanka'), findsOneWidget);
      expect(find.text('0112345678'), findsOneWidget);
      expect(find.text('Monday - Saturday, 8 AM - 6 PM'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(repository.callCount, 1);
      expect(repository.requestedHospitalIds, ['hospital-001']);
    });

    testWidgets('shows unavailable state when hospital does not exist', (
      tester,
    ) async {
      final repository = _FakeHospitalRepository((hospitalId, _) async => null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffHospitalOverviewPage(
              hospitalId: 'hospital-001',
              repository: repository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hospital unavailable'), findsOneWidget);
      expect(find.text('PetCare Animal Hospital'), findsNothing);
      expect(find.text('Check Again'), findsOneWidget);
    });

    testWidgets('does not display inactive hospital information', (
      tester,
    ) async {
      final repository = _FakeHospitalRepository(
        (hospitalId, _) async => _testHospital(active: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffHospitalOverviewPage(
              hospitalId: 'hospital-001',
              repository: repository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hospital unavailable'), findsOneWidget);
      expect(find.text('PetCare Animal Hospital'), findsNothing);
    });

    testWidgets('shows an error state when repository loading fails', (
      tester,
    ) async {
      final repository = _FakeHospitalRepository((hospitalId, _) async {
        throw StateError('Simulated Firestore failure');
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffHospitalOverviewPage(
              hospitalId: 'hospital-001',
              repository: repository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load hospital'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(repository.callCount, 1);
    });

    testWidgets('retries hospital loading after a failure', (tester) async {
      final repository = _FakeHospitalRepository((
        hospitalId,
        callNumber,
      ) async {
        if (callNumber == 1) {
          throw StateError('Simulated network failure');
        }

        return _testHospital();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffHospitalOverviewPage(
              hospitalId: 'hospital-001',
              repository: repository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load hospital'), findsOneWidget);
      expect(repository.callCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('PetCare Animal Hospital'), findsOneWidget);
      expect(repository.callCount, 2);
    });
  });
}
