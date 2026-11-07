import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/queue/domain/entities/queue.dart';
import 'package:petcare/features/queue/domain/repositories/queue_repository.dart';
import 'package:petcare/features/queue/presentation/pages/owner_queue_details_page.dart';

class _FakeQueueRepository implements QueueRepository {
  _FakeQueueRepository(this.queue);

  final Queue? queue;

  @override
  Future<Queue?> getQueueByAppointment(String appointmentId) async => queue;

  @override
  Future<Queue?> getQueueById(String queueId) async => queue;
}

class _FakeOwnerQueueRepository implements OwnerQueueRepository {
  _FakeOwnerQueueRepository(this.position);

  final int? position;
  int calls = 0;

  @override
  Future<int?> getOwnerQueuePosition({required String queueId}) async {
    calls++;
    return position;
  }
}

final appointment = Appointment(
  appointmentId: 'appointment-1',
  ownerId: 'owner-1',
  petId: 'pet-1',
  hospitalId: 'hospital-1',
  serviceId: 'service-1',
  vetId: 'vet-1',
  dateTime: DateTime(2026, 11, 7, 10, 30),
  reason: 'Checkup',
  status: 'confirmed',
  queueId: 'queue-1',
  createdAt: DateTime(2026, 11, 1),
);

Queue queueWithStatus(String status, {int number = 5}) => Queue(
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

Widget _pageFor({
  required Queue? queue,
  int? position,
  _FakeOwnerQueueRepository? positions,
}) {
  final ownerPositions = positions ?? _FakeOwnerQueueRepository(position);
  return MaterialApp(
    home: OwnerQueueDetailsPage(
      appointment: appointment,
      queueRepository: _FakeQueueRepository(queue),
      ownerQueueRepository: ownerPositions,
      petName: 'Milo',
      hospitalName: 'City Hospital',
      veterinarianName: 'Dr. Perera',
      serviceName: 'General Checkup',
    ),
  );
}

void main() {
  testWidgets('shows the server-calculated waiting position', (tester) async {
    await tester.pumpWidget(
      _pageFor(queue: queueWithStatus('waiting'), position: 3),
    );
    await tester.pumpAndSettle();

    expect(find.text('Queue number'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Waiting for your turn'), findsOneWidget);
    expect(find.text('You are number 3'), findsOneWidget);
    expect(find.text('2 waiting entries are ahead of you.'), findsOneWidget);
  });

  testWidgets('does not show a position when the owner has been called', (
    tester,
  ) async {
    final positions = _FakeOwnerQueueRepository(3);
    await tester.pumpWidget(
      _pageFor(queue: queueWithStatus('called'), positions: positions),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your turn has been called'), findsOneWidget);
    expect(find.text('Please proceed'), findsOneWidget);
    expect(find.textContaining('You are number'), findsNothing);
    expect(positions.calls, 0);
  });

  testWidgets('never substitutes the stored position when unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(_pageFor(queue: queueWithStatus('waiting')));
    await tester.pumpAndSettle();

    expect(find.text('Waiting position unavailable'), findsOneWidget);
    expect(find.textContaining('You are number'), findsNothing);
  });

  testWidgets('shows a clear not-checked-in state', (tester) async {
    await tester.pumpWidget(_pageFor(queue: null));
    await tester.pumpAndSettle();

    expect(find.text('Not checked in yet'), findsOneWidget);
    expect(find.textContaining('Queue details will appear'), findsOneWidget);
  });
}
