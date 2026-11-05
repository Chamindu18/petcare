import 'dart:convert';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare/features/appointments/data/datasources/appointment_scheduling_datasource.dart';

void main() {
  test(
    'network failures surface without reporting a successful booking',
    () async {
      final source = FirebaseAppointmentSchedulingDataSource(
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'owner'),
          signedIn: true,
        ),
        endpoint: Uri.parse('https://example.test/reserveAppointmentSlot'),
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        source.reserve({'action': 'create'}),
        throwsA(isA<http.ClientException>()),
      );
    },
  );

  test('permission denials preserve the server error message', () async {
    final source = FirebaseAppointmentSchedulingDataSource(
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'owner'), signedIn: true),
      endpoint: Uri.parse('https://example.test/reserveAppointmentSlot'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'status': 'PERMISSION_DENIED',
              'message': 'Hospital access denied.',
            },
          }),
          403,
        ),
      ),
    );
    await expectLater(
      source.reserve({'action': 'reassign'}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'Hospital access denied.',
        ),
      ),
    );
  });

  test('authenticated scheduling follows the callable protocol', () async {
    final source = FirebaseAppointmentSchedulingDataSource(
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'owner'), signedIn: true),
      endpoint: Uri.parse('https://example.test/reserveAppointmentSlot'),
      client: MockClient((request) async {
        expect(request.headers['Authorization'], startsWith('Bearer '));
        expect(jsonDecode(request.body), {
          'data': {'action': 'create'},
        });
        return http.Response(
          jsonEncode({
            'result': {'appointmentId': 'saved'},
          }),
          200,
        );
      }),
    );
    expect(
      (await source.reserve({'action': 'create'}))['appointmentId'],
      'saved',
    );
  });

  test(
    'server conflicts are surfaced instead of returning apparent success',
    () async {
      final source = FirebaseAppointmentSchedulingDataSource(
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'owner'),
          signedIn: true,
        ),
        endpoint: Uri.parse('https://example.test/reserveAppointmentSlot'),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'status': 'ALREADY_EXISTS',
                'message': 'This time is no longer available.',
              },
            }),
            409,
          ),
        ),
      );
      await expectLater(
        source.reserve({'action': 'create'}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'This time is no longer available.',
          ),
        ),
      );
    },
  );

  test('signed-out requests cannot reach the scheduling endpoint', () async {
    final source = FirebaseAppointmentSchedulingDataSource(
      auth: MockFirebaseAuth(signedIn: false),
      client: MockClient(
        (_) async => throw StateError('Network must not be called'),
      ),
    );
    await expectLater(source.reserve({'action': 'create'}), throwsStateError);
  });
}
