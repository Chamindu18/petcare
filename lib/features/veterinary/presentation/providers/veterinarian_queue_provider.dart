import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../queue/domain/entities/queue.dart';
import '../../../queue/domain/repositories/queue_repository.dart';

/// Queue state scoped to one verified veterinarian and hospital.
class VeterinarianQueueProvider extends ChangeNotifier {
  VeterinarianQueueProvider({
    required VeterinarianQueueRepository queueRepository,
    required String assignedHospitalId,
    required String assignedVeterinarianId,
    DateTime Function()? now,
  }) : _queue = queueRepository,
       _hospitalId = assignedHospitalId,
       _veterinarianId = assignedVeterinarianId,
       _now = now ?? DateTime.now;

  final VeterinarianQueueRepository _queue;
  final String _hospitalId;
  final String _veterinarianId;
  final DateTime Function() _now;

  List<Queue> _entries = [];
  DateTime? _loadedDay;
  bool _disposed = false;
  bool isLoading = false;
  bool isProcessing = false;
  String? errorMessage;
  String? actionMessage;

  List<Queue> get entries => List.unmodifiable(_entries);
  bool get canAct => !isLoading && !isProcessing && errorMessage == null;

  Future<void> refresh() async {
    if (_disposed || isLoading || isProcessing) return;
    actionMessage = null;
    await _load();
  }

  Future<void> _load() async {
    isLoading = true;
    errorMessage = null;
    _notify();
    try {
      final day = _hospitalDay(_now());
      final entries = await _queue.getVeterinarianQueue(
        hospitalId: _hospitalId,
        veterinarianId: _veterinarianId,
        date: day,
      );
      if (_disposed) return;
      _entries =
          entries
              .where(
                (queue) =>
                    queue.hospitalId == _hospitalId &&
                    queue.veterinarianId == _veterinarianId,
              )
              .toList()
            ..sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
      _loadedDay = day;
    } catch (error) {
      if (!_disposed) {
        _entries = [];
        errorMessage = _message(error, loading: true);
      }
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<bool> callPatient(Queue entry) =>
      _transition(entry, QueueStatus.called);

  Future<bool> startConsultation(Queue entry) =>
      _transition(entry, QueueStatus.inConsultation);

  Future<bool> completeConsultation(Queue entry) =>
      _transition(entry, QueueStatus.completed);

  Future<bool> skip(Queue entry) => _transition(entry, QueueStatus.skipped);

  Future<bool> cancel(Queue entry) => _transition(entry, QueueStatus.cancelled);

  Future<bool> _transition(Queue entry, QueueStatus next) {
    return _perform(() async {
      if (!_entries.any(
        (queue) =>
            queue.queueId == entry.queueId && queue.status == entry.status,
      )) {
        throw StateError('Queue status has changed.');
      }
      final expected = QueueStatus.fromValue(entry.status);
      if (!expected.canTransitionTo(next)) {
        throw StateError('Invalid queue status transition.');
      }
      await _queue.transitionStatus(
        queueId: entry.queueId,
        hospitalId: _hospitalId,
        expectedStatus: expected,
        nextStatus: next,
      );
    });
  }

  Future<bool> _perform(Future<void> Function() command) async {
    if (_disposed || !canAct) return false;
    isProcessing = true;
    actionMessage = null;
    _notify();
    var success = false;
    try {
      if (_loadedDay != _hospitalDay(_now())) {
        throw StateError('Hospital day has changed.');
      }
      await command();
      success = true;
      actionMessage = 'Queue updated.';
    } catch (error) {
      actionMessage = _message(error);
    }
    if (!_disposed) await _load();
    isProcessing = false;
    _notify();
    return success;
  }

  String _message(Object error, {bool loading = false}) {
    if ((error is FirebaseException &&
            ['permission-denied', 'unauthenticated'].contains(error.code)) ||
        (error is StateError &&
            error.message.toString().contains('assignment'))) {
      return 'Queue access denied. Your active veterinarian assignment is required.';
    }
    if (loading) return 'Unable to load your queue. Please retry.';
    if (error is StateError ||
        (error is FirebaseException &&
            [
              'aborted',
              'already-exists',
              'failed-precondition',
            ].contains(error.code))) {
      return 'This queue entry has changed. Review the refreshed data before trying again.';
    }
    return 'Unable to update the queue. Refresh and check its status before retrying.';
  }

  static DateTime _hospitalDay(DateTime instant) {
    final local = instant.toUtc().add(const Duration(minutes: 330));
    return DateTime.utc(local.year, local.month, local.day);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
