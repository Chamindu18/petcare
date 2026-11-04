import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../queue/domain/entities/queue.dart';
import '../../../queue/domain/repositories/queue_repository.dart';
import '../../domain/utils/staff_queue_eligibility.dart';

/// Staff state scoped to the hospital supplied by the verified access gate.
class StaffQueueProvider extends ChangeNotifier {
  StaffQueueProvider({
    required AppointmentRepository appointmentRepository,
    required StaffQueueCommandRepository queueRepository,
    required String assignedHospitalId,
    DateTime Function()? now,
  }) : _appointments = appointmentRepository,
       _queue = queueRepository,
       _hospitalId = assignedHospitalId,
       _now = now ?? DateTime.now;

  final AppointmentRepository _appointments;
  final StaffQueueCommandRepository _queue;
  final String _hospitalId;
  final DateTime Function() _now;
  List<Appointment> _eligible = [];
  List<Queue> _entries = [];
  DateTime? _loadedDay;
  bool _disposed = false;
  bool isLoading = false;
  bool isProcessing = false;
  String? errorMessage;
  String? actionMessage;
  List<Appointment> get eligibleAppointments => List.unmodifiable(_eligible);
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
      final now = _now();
      final day = _hospitalDay(now);
      final results = await Future.wait<Object>([
        _appointments.getAppointmentsByHospital(_hospitalId),
        _queue.getHospitalQueue(hospitalId: _hospitalId, date: day),
      ]);
      if (_disposed) return;
      final entries =
          (results[1] as List<Queue>)
              .where((q) => q.hospitalId == _hospitalId)
              .toList()
            ..sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
      _eligible =
          (results[0] as List<Appointment>)
              .where(
                (a) =>
                    StaffQueueEligibility.evaluate(
                      appointment: a,
                      assignedHospitalId: _hospitalId,
                      now: now,
                      utcOffset: const Duration(minutes: 330),
                    ).isEligible &&
                    !entries.any((q) => q.appointmentId == a.appointmentId),
              )
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _entries = entries;
      _loadedDay = day;
    } catch (error) {
      if (!_disposed) {
        _eligible = [];
        _entries = [];
        errorMessage = _message(error, loading: true);
      }
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<bool> checkIn(Appointment appointment) => _perform(() async {
    if (!_eligible.any((a) => a.appointmentId == appointment.appointmentId) ||
        !StaffQueueEligibility.evaluate(
          appointment: appointment,
          assignedHospitalId: _hospitalId,
          now: _now(),
          utcOffset: const Duration(minutes: 330),
        ).isEligible) {
      throw StateError('Appointment eligibility has changed.');
    }
    await _queue.checkInAppointment(
      appointmentId: appointment.appointmentId,
      hospitalId: _hospitalId,
    );
  });

  Future<bool> advance(Queue entry) => _perform(() async {
    if (!_entries.any(
      (q) => q.queueId == entry.queueId && q.status == entry.status,
    )) {
      throw StateError('Queue status has changed.');
    }
    final expected = StaffQueueStatus.fromValue(entry.status);
    final next = switch (expected) {
      StaffQueueStatus.waiting => StaffQueueStatus.inConsultation,
      StaffQueueStatus.inConsultation => StaffQueueStatus.completed,
      StaffQueueStatus.completed => throw StateError(
        'Queue already completed.',
      ),
    };
    await _queue.transitionStatus(
      queueId: entry.queueId,
      hospitalId: _hospitalId,
      expectedStatus: expected,
      nextStatus: next,
    );
  });

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
    // Refresh even on conflict: another staff member may have changed the queue.
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
      return 'Hospital access denied. Your active staff assignment is required.';
    }
    if (error is StateError ||
        (error is FirebaseException &&
            [
              'aborted',
              'already-exists',
              'failed-precondition',
            ].contains(error.code))) {
      return 'This appointment or queue has changed. Review the refreshed data before trying again.';
    }
    return loading
        ? 'Unable to load today\'s queue. Please retry.'
        : 'Unable to update the queue. Refresh and check its status before retrying.';
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
