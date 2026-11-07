import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/queue/domain/repositories/queue_repository.dart';

void main() {
  group('StaffQueueStatus', () {
    test('defines canonical Firestore status values', () {
      expect(StaffQueueStatus.waiting.value, 'waiting');
      expect(StaffQueueStatus.called.value, 'called');
      expect(StaffQueueStatus.inConsultation.value, 'in_consultation');
      expect(StaffQueueStatus.completed.value, 'completed');
      expect(StaffQueueStatus.skipped.value, 'skipped');
      expect(StaffQueueStatus.cancelled.value, 'cancelled');
    });

    test('parses every supported queue status', () {
      expect(StaffQueueStatus.fromValue('waiting'), StaffQueueStatus.waiting);
      expect(StaffQueueStatus.fromValue('called'), StaffQueueStatus.called);

      expect(
        StaffQueueStatus.fromValue('in_consultation'),
        StaffQueueStatus.inConsultation,
      );

      expect(
        StaffQueueStatus.fromValue('completed'),
        StaffQueueStatus.completed,
      );

      expect(StaffQueueStatus.fromValue('skipped'), StaffQueueStatus.skipped);
      expect(
        StaffQueueStatus.fromValue('cancelled'),
        StaffQueueStatus.cancelled,
      );
    });

    test('distinguishes active and terminal statuses', () {
      for (final status in [
        StaffQueueStatus.waiting,
        StaffQueueStatus.called,
        StaffQueueStatus.inConsultation,
      ]) {
        expect(status.isTerminal, isFalse);
        expect(status.isActive, isTrue);
      }

      for (final status in [
        StaffQueueStatus.completed,
        StaffQueueStatus.skipped,
        StaffQueueStatus.cancelled,
      ]) {
        expect(status.isTerminal, isTrue);
        expect(status.isActive, isFalse);
      }

      expect(StaffQueueStatus.waiting.isWaiting, isTrue);
      expect(StaffQueueStatus.called.isInProgress, isTrue);
      expect(StaffQueueStatus.inConsultation.isInProgress, isTrue);
    });

    test('allows only the forward lifecycle and terminal exits', () {
      final expected = {
        StaffQueueStatus.waiting: {
          StaffQueueStatus.called,
          StaffQueueStatus.skipped,
          StaffQueueStatus.cancelled,
        },
        StaffQueueStatus.called: {
          StaffQueueStatus.inConsultation,
          StaffQueueStatus.skipped,
          StaffQueueStatus.cancelled,
        },
        StaffQueueStatus.inConsultation: {
          StaffQueueStatus.completed,
          StaffQueueStatus.cancelled,
        },
        StaffQueueStatus.completed: <StaffQueueStatus>{},
        StaffQueueStatus.skipped: <StaffQueueStatus>{},
        StaffQueueStatus.cancelled: <StaffQueueStatus>{},
      };

      for (final status in StaffQueueStatus.values) {
        for (final next in StaffQueueStatus.values) {
          expect(
            status.canTransitionTo(next),
            expected[status]!.contains(next),
            reason: '${status.value} -> ${next.value}',
          );
        }
      }
    });

    test('returns null when an optional status cannot be parsed', () {
      expect(StaffQueueStatus.tryParse(null), isNull);
      expect(StaffQueueStatus.tryParse('unknown'), isNull);
      expect(
        StaffQueueStatus.tryParse(' CANCELLED '),
        StaffQueueStatus.cancelled,
      );
    });

    test('normalizes whitespace and letter case', () {
      expect(StaffQueueStatus.fromValue(' WAITING '), StaffQueueStatus.waiting);

      expect(
        StaffQueueStatus.fromValue(' In_Consultation '),
        StaffQueueStatus.inConsultation,
      );

      expect(
        StaffQueueStatus.fromValue(' COMPLETED '),
        StaffQueueStatus.completed,
      );

      expect(StaffQueueStatus.fromValue(' SKIPPED '), StaffQueueStatus.skipped);
    });

    test('rejects unsupported queue statuses', () {
      for (final status in [
        'pending',
        'confirmed',
        'rejected',
        'checked_in',
        'no_show',
        'unknown',
      ]) {
        expect(
          () => StaffQueueStatus.fromValue(status),
          throwsA(isA<FormatException>()),
          reason: 'Unsupported status "$status" must be rejected.',
        );
      }
    });

    test('rejects empty and whitespace-only statuses', () {
      for (final status in ['', ' ', '   ']) {
        expect(
          () => StaffQueueStatus.fromValue(status),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('round-trips every supported status', () {
      for (final status in StaffQueueStatus.values) {
        final encoded = status.value;
        final decoded = StaffQueueStatus.fromValue(encoded);

        expect(decoded, status);
        expect(decoded.value, encoded);
      }
    });

    test('does not accept ambiguous status spelling', () {
      for (final status in [
        'in consultation',
        'in-consultation',
        'inConsultation',
        'complete',
        'wait',
      ]) {
        expect(
          () => StaffQueueStatus.fromValue(status),
          throwsA(isA<FormatException>()),
        );
      }
    });
  });
}
