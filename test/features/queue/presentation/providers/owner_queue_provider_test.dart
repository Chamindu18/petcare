import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/queue/domain/entities/queue.dart';
import 'package:petcare/features/queue/domain/repositories/queue_repository.dart';
import 'package:petcare/features/queue/presentation/providers/owner_queue_provider.dart';

class _FakeQueueRepository implements QueueRepository {
  _FakeQueueRepository({this.queue, this.error, this.pending});

  Queue? queue;
  Object? error;
  int calls = 0;
  String? lastAppointmentId;
  Completer<Queue?>? pending;

  @override
  Future<Queue?> getQueueByAppointment(String appointmentId) async {
    calls++;
    lastAppointmentId = appointmentId;
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return queue;
  }

  @override
  Future<Queue?> getQueueById(String queueId) async => queue;
}

class _FakeOwnerQueueRepository implements OwnerQueueRepository {
  _FakeOwnerQueueRepository({this.position, this.error});

  int? position;
  Object? error;
  int calls = 0;
  String? lastQueueId;

  @override
  Future<int?> getOwnerQueuePosition({required String queueId}) async {
    calls++;
    lastQueueId = queueId;
    if (error != null) throw error!;
    return position;
  }
}

Queue queueWithStatus(String status, {int number = 2}) => Queue(
  queueId: 'queue-1',
  appointmentId: 'appointment-1',
  queueNumber: number,
  currentServing: 0,
  position: number,
  status: status,
  updatedAt: DateTime.utc(2026, 11, 7, 10),
  hospitalId: 'hospital-1',
  ownerId: 'owner-1',
  petId: 'pet-1',
);

void main() {
  test('loads the linked queue and waiting position', () async {
    final queues = _FakeQueueRepository(queue: queueWithStatus('waiting'));
    final positions = _FakeOwnerQueueRepository(position: 2);
    final provider = OwnerQueueProvider(
      queueRepository: queues,
      ownerQueueRepository: positions,
      appointmentId: 'appointment-1',
    );

    await provider.load();

    expect(queues.lastAppointmentId, 'appointment-1');
    expect(provider.queue?.queueId, 'queue-1');
    expect(provider.position, 2);
    expect(positions.lastQueueId, 'queue-1');
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('does not request a position for a called queue', () async {
    final queues = _FakeQueueRepository(queue: queueWithStatus('called'));
    final positions = _FakeOwnerQueueRepository(position: 2);
    final provider = OwnerQueueProvider(
      queueRepository: queues,
      ownerQueueRepository: positions,
      appointmentId: 'appointment-1',
    );

    await provider.load();

    expect(provider.queue?.status, 'called');
    expect(provider.position, isNull);
    expect(positions.calls, 0);
  });

  test('keeps queue details when the position request fails', () async {
    final queues = _FakeQueueRepository(queue: queueWithStatus('waiting'));
    final positions = _FakeOwnerQueueRepository(error: StateError('offline'));
    final provider = OwnerQueueProvider(
      queueRepository: queues,
      ownerQueueRepository: positions,
      appointmentId: 'appointment-1',
    );

    await provider.load();

    expect(provider.queue, isNotNull);
    expect(provider.position, isNull);
    expect(provider.errorMessage, isNull);
  });

  test('surfaces a safe queue loading error', () async {
    final queues = _FakeQueueRepository(error: StateError('denied'));
    final provider = OwnerQueueProvider(
      queueRepository: queues,
      appointmentId: 'appointment-1',
    );

    await provider.load();

    expect(provider.queue, isNull);
    expect(
      provider.errorMessage,
      'Unable to load queue details. Please try again.',
    );
    expect(provider.isLoading, isFalse);
  });

  test(
    'refreshes queue status and waiting position without stale position',
    () async {
      final queues = _FakeQueueRepository(queue: queueWithStatus('waiting'));
      final positions = _FakeOwnerQueueRepository(position: 3);
      final provider = OwnerQueueProvider(
        queueRepository: queues,
        ownerQueueRepository: positions,
        appointmentId: 'appointment-1',
      );
      await provider.load();
      expect(provider.position, 3);
      positions.position = 2;
      await provider.load();
      expect(provider.position, 2);
      queues.queue = queueWithStatus('called');
      await provider.load();
      expect(provider.queue?.status, 'called');
      expect(provider.position, isNull);
      expect(positions.calls, 2);
      provider.dispose();
    },
  );

  test('clears previously visible queue when a later read is denied', () async {
    final queues = _FakeQueueRepository(queue: queueWithStatus('waiting'));
    final provider = OwnerQueueProvider(
      queueRepository: queues,
      appointmentId: 'appointment-1',
    );
    await provider.load();
    queues.error = StateError('permission-denied');
    await provider.load();
    expect(provider.queue, isNull);
    expect(provider.position, isNull);
    expect(provider.errorMessage, isNotNull);
    provider.dispose();
  });

  test('does not apply a pending read after disposal', () async {
    final queues = _FakeQueueRepository(pending: Completer<Queue?>());
    final provider = OwnerQueueProvider(
      queueRepository: queues,
      appointmentId: 'appointment-1',
    );
    final loading = provider.load();
    provider.dispose();
    queues.pending!.complete(queueWithStatus('waiting'));
    await loading;
    expect(provider.queue, isNull);
  });
}
