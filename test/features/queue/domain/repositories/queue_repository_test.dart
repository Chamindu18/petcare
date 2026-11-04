import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/queue/domain/repositories/queue_repository.dart';

void main() {
  group('StaffQueueStatus', () {
    test('defines canonical Firestore status values', () {
      expect(StaffQueueStatus.waiting.value, 'waiting');

      expect(StaffQueueStatus.inConsultation.value, 'in_consultation');

      expect(StaffQueueStatus.completed.value, 'completed');
    });

    test('parses every supported queue status', () {
      expect(StaffQueueStatus.fromValue('waiting'), StaffQueueStatus.waiting);

      expect(
        StaffQueueStatus.fromValue('in_consultation'),
        StaffQueueStatus.inConsultation,
      );

      expect(
        StaffQueueStatus.fromValue('completed'),
        StaffQueueStatus.completed,
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
    });

    test('rejects unsupported queue statuses', () {
      for (final status in [
        'pending',
        'confirmed',
        'cancelled',
        'rejected',
        'checked_in',
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
