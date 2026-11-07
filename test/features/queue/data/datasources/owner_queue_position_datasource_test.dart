import 'dart:convert';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare/features/queue/data/datasources/owner_queue_position_datasource.dart';

void main() {
  test('owner position request follows the callable protocol', () async {
    final source = FirebaseOwnerQueuePositionDataSource(
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'owner'), signedIn: true),
      endpoint: Uri.parse('https://example.test/getOwnerQueuePosition'),
      client: MockClient((request) async {
        expect(request.headers['Authorization'], startsWith('Bearer '));
        expect(jsonDecode(request.body), {
          'data': {'queueId': 'queue-1'},
        });
        return http.Response(
          jsonEncode({
            'result': {'position': 3, 'status': 'waiting'},
          }),
          200,
        );
      }),
    );

    expect(await source.fetchPosition(queueId: 'queue-1'), {
      'position': 3,
      'status': 'waiting',
    });
  });

  test('owner position errors are surfaced safely', () async {
    final source = FirebaseOwnerQueuePositionDataSource(
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'owner'), signedIn: true),
      endpoint: Uri.parse('https://example.test/getOwnerQueuePosition'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'status': 'NOT_FOUND',
              'message': 'Queue entry was not found.',
            },
          }),
          404,
        ),
      ),
    );

    await expectLater(
      source.fetchPosition(queueId: 'queue-1'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Queue entry was not found.',
        ),
      ),
    );
  });

  test('signed-out requests cannot reach the position endpoint', () async {
    final source = FirebaseOwnerQueuePositionDataSource(
      auth: MockFirebaseAuth(signedIn: false),
      client: MockClient(
        (_) async => throw StateError('Network must not be called'),
      ),
    );

    await expectLater(
      source.fetchPosition(queueId: 'queue-1'),
      throwsStateError,
    );
  });
}
