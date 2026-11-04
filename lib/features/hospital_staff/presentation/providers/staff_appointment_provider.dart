import 'package:flutter/foundation.dart';

import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';

/// Manages hospital-scoped appointments and staff decisions.
///
/// This provider is intentionally separate from the veterinarian appointment
/// provider so staff-specific actions do not affect the veterinarian dashboard.
class StaffAppointmentProvider extends ChangeNotifier {
  StaffAppointmentProvider({
    required AppointmentRepository appointmentRepository,
    required String assignedHospitalId,
  }) : _repository = appointmentRepository,
       _hospitalId = assignedHospitalId;

  final AppointmentRepository _repository;
  final String _hospitalId;

  List<Appointment> _appointments = [];
  final Set<String> _processingAppointmentIds = {};

  bool _isLoading = false;
  bool _isDisposed = false;

  String? _errorMessage;
  String? _actionErrorMessage;

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get actionErrorMessage => _actionErrorMessage;

  bool isProcessing(String appointmentId) =>
      _processingAppointmentIds.contains(appointmentId);

  /// Loads appointments belonging exclusively to the assigned hospital.
  Future<void> loadAppointments() async {
    if (_isDisposed) return;

    _isLoading = true;
    _errorMessage = null;
    _actionErrorMessage = null;
    _notifyIfActive();

    try {
      final loadedAppointments = await _repository.getAppointmentsByHospital(
        _hospitalId,
      );

      if (_isDisposed) return;

      // Copy the collection before sorting to avoid modifying repository data.
      final sortedAppointments = List<Appointment>.of(loadedAppointments)
        ..sort((first, second) => first.dateTime.compareTo(second.dateTime));

      _appointments = sortedAppointments;
    } catch (error, stackTrace) {
      debugPrint('Staff appointment loading error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!_isDisposed) {
        _errorMessage =
            'Unable to load hospital appointments. Please try again.';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _notifyIfActive();
      }
    }
  }

  /// Confirms a pending appointment.
  Future<bool> confirmAppointment(String appointmentId) {
    return _performDecision(
      appointmentId: appointmentId,
      action: _repository.confirmAppointment,
      nextStatus: 'confirmed',
    );
  }

  /// Rejects a pending appointment.
  Future<bool> rejectAppointment(String appointmentId) {
    return _performDecision(
      appointmentId: appointmentId,
      action: _repository.rejectAppointment,
      nextStatus: 'rejected',
    );
  }

  Future<bool> reassignVeterinarian(String appointmentId, String vetId) async {
    if (_isDisposed || isProcessing(appointmentId)) return false;
    final repository = _repository;
    if (repository is! AppointmentAssignmentRepository) return false;
    _processingAppointmentIds.add(appointmentId);
    _actionErrorMessage = null;
    _notifyIfActive();
    try {
      await (repository as AppointmentAssignmentRepository)
          .reassignVeterinarian(
            appointmentId: appointmentId,
            hospitalId: _hospitalId,
            vetId: vetId,
          );
      await loadAppointments();
      return true;
    } catch (error) {
      if (!_isDisposed) _actionErrorMessage = 'Unable to reassign: $error';
      return false;
    } finally {
      _processingAppointmentIds.remove(appointmentId);
      _notifyIfActive();
    }
  }

  Future<bool> _performDecision({
    required String appointmentId,
    required Future<void> Function(String) action,
    required String nextStatus,
  }) async {
    if (_isDisposed || _processingAppointmentIds.contains(appointmentId)) {
      return false;
    }

    _actionErrorMessage = null;
    _processingAppointmentIds.add(appointmentId);
    _notifyIfActive();

    try {
      await action(appointmentId);

      if (_isDisposed) return true;

      _updateLocalAppointmentStatus(
        appointmentId: appointmentId,
        status: nextStatus,
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint('Staff appointment decision error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!_isDisposed) {
        final actionVerb = nextStatus == 'confirmed' ? 'confirm' : 'reject';

        _actionErrorMessage =
            'Unable to $actionVerb this appointment. '
            'Please refresh and try again.';
      }

      return false;
    } finally {
      _processingAppointmentIds.remove(appointmentId);
      _notifyIfActive();
    }
  }

  /// Replaces the updated appointment without refetching the entire list.
  void _updateLocalAppointmentStatus({
    required String appointmentId,
    required String status,
  }) {
    _appointments = _appointments.map((appointment) {
      if (appointment.appointmentId != appointmentId) {
        return appointment;
      }

      return Appointment(
        appointmentId: appointment.appointmentId,
        ownerId: appointment.ownerId,
        petId: appointment.petId,
        hospitalId: appointment.hospitalId,
        serviceId: appointment.serviceId,
        vetId: appointment.vetId,
        dateTime: appointment.dateTime,
        reason: appointment.reason,
        status: status,
        queueId: appointment.queueId,
        createdAt: appointment.createdAt,
      );
    }).toList();
  }

  void clearErrors() {
    if (_isDisposed || (_errorMessage == null && _actionErrorMessage == null)) {
      return;
    }

    _errorMessage = null;
    _actionErrorMessage = null;
    _notifyIfActive();
  }

  void _notifyIfActive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    super.dispose();
  }
}
