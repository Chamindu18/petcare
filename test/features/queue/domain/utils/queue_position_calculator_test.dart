import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/queue/domain/entities/queue.dart';
import 'package:petcare/features/queue/domain/utils/queue_position_calculator.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 10);

  Queue entry(
    String id,
    int number,
    String status, {
    String hospital = 'hospital',
    DateTime? createdAt,
  }) => Queue(
    queueId: id,
    appointmentId: 'appointment-$id',
    hospitalId: hospital,
    ownerId: 'owner',
    petId: 'pet',
    queueNumber: number,
    currentServing: 0,
    position: number,
    status: status,
    updatedAt: now,
    createdAt: createdAt,
  );

  test('waiting entries are numbered by allocation order', () {
    final entries = [
      entry('c', 3, 'waiting'),
      entry('a', 1, 'waiting'),
      entry('b', 2, 'waiting'),
    ];

    expect(
      QueuePositionCalculator.calculate(
        hospitalId: 'hospital',
        hospitalDayEntries: entries,
      ),
      {'a': 1, 'b': 2, 'c': 3},
    );
  });

  test('non-waiting and other-hospital entries do not consume positions', () {
    final entries = [
      entry('a', 1, 'waiting'),
      entry('b', 2, 'called'),
      entry('c', 3, 'in_consultation'),
      entry('d', 4, 'completed'),
      entry('e', 5, 'cancelled'),
      entry('f', 6, 'waiting', hospital: 'other'),
      entry('g', 7, 'waiting'),
    ];

    expect(
      QueuePositionCalculator.calculate(
        hospitalId: 'hospital',
        hospitalDayEntries: entries,
      ),
      {'a': 1, 'g': 2},
    );
    expect(
      QueuePositionCalculator.positionFor(
        entry: entries[2],
        hospitalDayEntries: entries,
      ),
      0,
    );
    expect(
      QueuePositionCalculator.positionFor(
        entry: entries[6],
        hospitalDayEntries: entries,
      ),
      2,
    );
  });

  test(
    'unknown statuses are excluded and duplicate numbers are deterministic',
    () {
      final entries = [
        entry('z', 2, 'waiting'),
        entry('y', 2, 'waiting'),
        entry('x', 1, 'unknown'),
      ];

      expect(
        QueuePositionCalculator.calculate(
          hospitalId: 'hospital',
          hospitalDayEntries: entries,
        ),
        {'y': 1, 'z': 2},
      );
    },
  );
}
