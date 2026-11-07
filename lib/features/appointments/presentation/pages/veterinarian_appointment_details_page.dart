import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/petcare_secondary_app_bar.dart';
import '../../domain/entities/appointment.dart';
import '../widgets/appointment_status_badge.dart';

class VeterinarianAppointmentDetailsPage extends StatefulWidget {
  const VeterinarianAppointmentDetailsPage({
    super.key,
    required this.appointment,
    required this.serviceName,
    required this.onConfirm,
    required this.onReject,
    this.hospitalName,
    this.actionErrorProvider,
    this.onManageQueue,
  });

  final Appointment appointment;
  final String? serviceName;
  final String? hospitalName;
  final Future<bool> Function(String appointmentId) onConfirm;
  final Future<bool> Function(String appointmentId) onReject;
  final String? Function()? actionErrorProvider;
  final VoidCallback? onManageQueue;

  @override
  State<VeterinarianAppointmentDetailsPage> createState() =>
      _VeterinarianAppointmentDetailsPageState();
}

class _VeterinarianAppointmentDetailsPageState
    extends State<VeterinarianAppointmentDetailsPage> {
  late Appointment _appointment = widget.appointment;

  bool _isProcessing = false;
  String? _actionErrorMessage;

  String get _status => _appointment.status.trim().toLowerCase();

  bool get _isPending => _status == 'pending';
  bool get _isConfirmed => _status == 'confirmed';
  bool get _isTerminal =>
      _status == 'cancelled' || _status == 'rejected' || _status == 'completed';

  String get _serviceName {
    final name = widget.serviceName?.trim();
    return name == null || name.isEmpty
        ? 'Service information unavailable'
        : name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const PetCareSecondaryAppBar(title: 'Appointment Details'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 18),
          _buildAccessNotice(),
          const SizedBox(height: 18),
          _sectionTitle('Appointment information'),
          const SizedBox(height: 10),
          _buildInformationCard(),
          const SizedBox(height: 18),
          _sectionTitle('Actions'),
          const SizedBox(height: 10),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppTheme.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDateTime(_appointment.dateTime),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.deepBrown,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppointmentStatusBadge(status: _appointment.status),
            ],
          ),
          if (_appointment.reason.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Reason for visit',
              style: TextStyle(
                color: AppTheme.deepBrown,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _appointment.reason.trim(),
              style: const TextStyle(
                color: AppTheme.espresso,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.deepBrown,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Owner and pet identity details are not available under the '
              'current veterinary access rules. Use the authorized '
              'health-passport flow when it becomes available.',
              style: TextStyle(
                color: AppTheme.deepBrown.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.local_hospital_outlined,
            label: 'Hospital',
            value: _displayValue(widget.hospitalName),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.medical_services_outlined,
            label: 'Service',
            value: _serviceName,
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.pets_outlined,
            label: 'Pet reference',
            value: _shortId(_appointment.petId),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Appointment reference',
            value: _shortId(_appointment.appointmentId),
          ),
          if (_appointment.queueId?.trim().isNotEmpty == true) ...[
            const Divider(height: 1),
            _DetailRow(
              icon: Icons.groups_outlined,
              label: 'Queue reference',
              value: _shortId(_appointment.queueId!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_isProcessing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_actionErrorMessage != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _actionErrorMessage!,
          style: const TextStyle(color: AppTheme.error, fontSize: 12),
        ),
      );
    }

    if (_isPending) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Confirm appointment'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reject,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error.withValues(alpha: 0.75)),
              ),
            ),
          ),
        ],
      );
    }

    if (_isConfirmed) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showNotAvailable(
                'QR Health Passport',
                'The appointment-linked QR Health Passport is not available '
                    'in this phase. No QR code has been generated.',
              ),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Open pet health passport'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openQueue,
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Manage queue'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Consultation notes and appointment completion are not available '
            'in this phase.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.deepBrown.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    if (_isTerminal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'This appointment is ${_status.replaceAll('_', ' ')}. '
          'No further actions are available.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.deepBrown, fontSize: 12),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _confirm() async {
    final confirmed = await _confirmDialog(
      title: 'Confirm appointment?',
      message: 'The owner will see this appointment as confirmed.',
      confirmLabel: 'Confirm',
    );

    if (confirmed != true) return;

    await _runDecision(
      action: () => widget.onConfirm(_appointment.appointmentId),
      nextStatus: 'confirmed',
      successMessage: 'Appointment confirmed.',
    );
  }

  Future<void> _reject() async {
    final rejected = await _confirmDialog(
      title: 'Reject appointment?',
      message: 'Rejecting a pending appointment cannot be undone.',
      confirmLabel: 'Reject',
      destructive: true,
    );

    if (rejected != true) return;

    await _runDecision(
      action: () => widget.onReject(_appointment.appointmentId),
      nextStatus: 'rejected',
      successMessage: 'Appointment rejected.',
    );
  }

  Future<void> _runDecision({
    required Future<bool> Function() action,
    required String nextStatus,
    required String successMessage,
  }) async {
    setState(() {
      _isProcessing = true;
      _actionErrorMessage = null;
    });

    final success = await action();

    if (!mounted) return;

    setState(() {
      _isProcessing = false;

      if (success) {
        _appointment = _withStatus(_appointment, nextStatus);
      } else {
        _actionErrorMessage =
            widget.actionErrorProvider?.call() ??
            'Unable to update the appointment. Please try again.';
      }
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? successMessage : _actionErrorMessage!)),
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: AppTheme.error)
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  void _openQueue() {
    if (widget.onManageQueue == null) {
      _showNotAvailable(
        'Queue management',
        'Live queue management is not available in this phase.',
      );
      return;
    }
    if (_appointment.queueId?.trim().isEmpty ?? true) {
      _showNotAvailable(
        'Queue management',
        'This appointment has not been checked in to the queue yet. '
            'Hospital staff must check in the patient first.',
      );
      return;
    }
    widget.onManageQueue!();
  }

  void _showNotAvailable(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
    );
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Not available' : trimmed;
  }

  String _shortId(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return 'Unknown';
    return trimmed.length <= 10
        ? trimmed.toUpperCase()
        : trimmed.substring(0, 10).toUpperCase();
  }

  String _formatDateTime(DateTime dateTime) {
    dateTime = dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));
    final time = TimeOfDay.fromDateTime(dateTime).format(context);

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} · $time';
  }

  Appointment _withStatus(Appointment appointment, String status) {
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
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primary, size: 21),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.deepBrown,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: AppTheme.espresso, fontSize: 13),
      ),
    );
  }
}
