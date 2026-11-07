import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/queue/data/datasources/owner_queue_position_datasource.dart';
import 'package:petcare/features/queue/data/repositories/firebase_queue_repository.dart';

class _FakePositionDataSource implements OwnerQueuePositionDataSource {
  _FakePositionDataSource(this.result);

  final Map<String, dynamic> result;
  String? lastQueueId;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchPosition({required String queueId}) async {
    calls++;
    lastQueueId = queueId;
    return result;
  }
}

void main() {
  late _FakePositionDataSource source;
  late FirebaseQueueRepository repository;

  FirebaseQueueRepository buildRepository() => FirebaseQueueRepository(
    firestore: FakeFirebaseFirestore(),
    auth: MockFirebaseAuth(mockUser: MockUser(uid: 'owner'), signedIn: true),
    ownerQueuePositionDataSource: source,
  );

  setUp(() {
    source = _FakePositionDataSource({'position': 3, 'status': 'waiting'});
    repository = buildRepository();
  });

  test('returns the positive server-calculated position', () async {
    expect(await repository.getOwnerQueuePosition(queueId: 'queue-1'), 3);
    expect(source.lastQueueId, 'queue-1');
    expect(source.calls, 1);
  });

  test('does not expose zero or non-integer positions', () async {
    for (final position in [0, -1, '3', null]) {
      source = _FakePositionDataSource({'position': position});
      repository = buildRepository();
      expect(
        await repository.getOwnerQueuePosition(queueId: 'queue-1'),
        isNull,
      );
    }
  });

  test('empty queue identifiers do not reach the server', () async {
    expect(await repository.getOwnerQueuePosition(queueId: '  '), isNull);
    expect(source.calls, 0);
  });
}
