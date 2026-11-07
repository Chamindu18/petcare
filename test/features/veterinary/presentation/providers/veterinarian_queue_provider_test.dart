import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/queue/domain/entities/queue.dart';
import 'package:petcare/features/queue/domain/repositories/queue_repository.dart';
import 'package:petcare/features/veterinary/presentation/pages/veterinarian_queue_page.dart';
import 'package:petcare/features/veterinary/presentation/providers/veterinarian_queue_provider.dart';

Queue queue({
  required String id,
  String hospitalId = 'hospital',
  String veterinarianId = 'vet',
  String status = 'waiting',
  int number = 1,
}) {
  return Queue(
    queueId: id,
    appointmentId: 'appointment-$id',
    queueNumber: number,
    currentServing: 0,
    position: number,
    status: status,
    updatedAt: DateTime.utc(2026, 11, 3, 10),
    hospitalId: hospitalId,
    ownerId: 'owner',
    petId: 'pet',
    veterinarianId: veterinarianId,
  );
}

class FakeVeterinarianQueueRepository implements VeterinarianQueueRepository {
  FakeVeterinarianQueueRepository(this.entries);

  List<Queue> entries;
  Object? loadError;
  Object? transitionError;
  int loadCalls = 0;
  String? lastHospitalId;
  String? lastVeterinarianId;

  @override
  Future<List<Queue>> getVeterinarianQueue({
    required String hospitalId,
    required String veterinarianId,
    required DateTime date,
  }) async {
    loadCalls++;
    lastHospitalId = hospitalId;
    lastVeterinarianId = veterinarianId;
    if (loadError != null) throw loadError!;
    return List.of(entries);
  }

  @override
  Future<Queue> transitionStatus({
    required String queueId,
    required String hospitalId,
    required StaffQueueStatus expectedStatus,
    required StaffQueueStatus nextStatus,
  }) async {
    if (transitionError != null) throw transitionError!;
    final index = entries.indexWhere((entry) => entry.queueId == queueId);
    final current = entries[index];
    entries[index] = Queue(
      queueId: current.queueId,
      appointmentId: current.appointmentId,
      queueNumber: current.queueNumber,
      currentServing: current.currentServing,
      position: 0,
      status: nextStatus.value,
      updatedAt: DateTime.utc(2026, 11, 3, 11),
      hospitalId: current.hospitalId,
      ownerId: current.ownerId,
      petId: current.petId,
      veterinarianId: current.veterinarianId,
    );
    return entries[index];
  }
}

void main() {
  test('loads only the authenticated veterinarian queue', () async {
    final repository = FakeVeterinarianQueueRepository([
      queue(id: 'mine'),
      queue(id: 'other-vet', veterinarianId: 'other-vet'),
      queue(id: 'other-hospital', hospitalId: 'other'),
    ]);
    final provider = VeterinarianQueueProvider(
      queueRepository: repository,
      assignedHospitalId: 'hospital',
      assignedVeterinarianId: 'vet',
      now: () => DateTime.utc(2026, 11, 3, 10),
    );
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(provider.entries.map((entry) => entry.queueId), ['mine']);
    expect(repository.lastHospitalId, 'hospital');
    expect(repository.lastVeterinarianId, 'vet');
    expect(provider.errorMessage, isNull);
  });

  test('queue action transitions and refreshes the assigned queue', () async {
    final repository = FakeVeterinarianQueueRepository([queue(id: 'mine')]);
    final provider = VeterinarianQueueProvider(
      queueRepository: repository,
      assignedHospitalId: 'hospital',
      assignedVeterinarianId: 'vet',
      now: () => DateTime.utc(2026, 11, 3, 10),
    );
    addTearDown(provider.dispose);
    await provider.refresh();

    expect(await provider.callPatient(provider.entries.single), isTrue);

    expect(provider.entries.single.status, 'called');
    expect(provider.actionMessage, 'Queue updated.');
    expect(repository.loadCalls, 2);
  });

  test('load failure is surfaced and retry recovers', () async {
    final repository = FakeVeterinarianQueueRepository([queue(id: 'mine')]);
    repository.loadError = StateError('unavailable');
    final provider = VeterinarianQueueProvider(
      queueRepository: repository,
      assignedHospitalId: 'hospital',
      assignedVeterinarianId: 'vet',
      now: () => DateTime.utc(2026, 11, 3, 10),
    );
    addTearDown(provider.dispose);

    await provider.refresh();
    expect(provider.errorMessage, contains('Unable to load your queue'));

    repository.loadError = null;
    await provider.refresh();
    expect(provider.errorMessage, isNull);
    expect(provider.entries.single.queueId, 'mine');
  });

  test(
    'stale queue action fails without replacing the current state',
    () async {
      final repository = FakeVeterinarianQueueRepository([queue(id: 'mine')]);
      final provider = VeterinarianQueueProvider(
        queueRepository: repository,
        assignedHospitalId: 'hospital',
        assignedVeterinarianId: 'vet',
        now: () => DateTime.utc(2026, 11, 3, 10),
      );
      addTearDown(provider.dispose);
      await provider.refresh();
      repository.transitionError = StateError('Queue status has changed.');

      expect(await provider.callPatient(provider.entries.single), isFalse);

      expect(provider.actionMessage, contains('changed'));
      expect(provider.entries.single.status, 'waiting');
    },
  );

  testWidgets('queue page displays the assigned queue and transitions it', (
    tester,
  ) async {
    final repository = FakeVeterinarianQueueRepository([queue(id: 'mine')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VeterinarianQueuePage(
            hospitalId: 'hospital',
            veterinarianId: 'vet',
            queueRepository: repository,
            now: () => DateTime.utc(2026, 11, 3, 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's queue"), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('Call patient'), findsOneWidget);

    await tester.tap(find.text('Call patient'));
    await tester.pumpAndSettle();

    expect(find.text('Called'), findsOneWidget);
    expect(find.text('Start consultation'), findsOneWidget);
  });

  testWidgets('queue page shows an empty assigned queue state', (tester) async {
    final repository = FakeVeterinarianQueueRepository([]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VeterinarianQueuePage(
            hospitalId: 'hospital',
            veterinarianId: 'vet',
            queueRepository: repository,
            now: () => DateTime.utc(2026, 11, 3, 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No patients in your queue'), findsOneWidget);
  });
}
