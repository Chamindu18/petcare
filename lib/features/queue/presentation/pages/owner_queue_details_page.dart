import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../domain/entities/queue.dart';
import '../../domain/repositories/queue_repository.dart';
import '../providers/owner_queue_provider.dart';
import '../widgets/owner_queue_status_badge.dart';

/// Owner-facing live queue details for one appointment.
class OwnerQueueDetailsPage extends StatefulWidget {
  const OwnerQueueDetailsPage({
    required this.appointment,
    required this.queueRepository,
    required this.ownerQueueRepository,
    this.initialQueue,
    this.petName,
    this.hospitalName,
    this.veterinarianName,
    this.serviceName,
    super.key,
  });

  final Appointment appointment;
  final QueueRepository queueRepository;
  final OwnerQueueRepository ownerQueueRepository;
  final Queue? initialQueue;
  final String? petName;
  final String? hospitalName;
  final String? veterinarianName;
  final String? serviceName;

  @override
  State<OwnerQueueDetailsPage> createState() => _OwnerQueueDetailsPageState();
}

class _OwnerQueueDetailsPageState extends State<OwnerQueueDetailsPage> {
  late final OwnerQueueProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = OwnerQueueProvider(
      queueRepository: widget.queueRepository,
      ownerQueueRepository: widget.ownerQueueRepository,
      appointmentId: widget.appointment.appointmentId,
      initialQueue: widget.initialQueue,
    );
    _provider.load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Live Queue')),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          final queue = _provider.queue;

          if (_provider.isLoading && queue == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.errorMessage != null && queue == null) {
            return _QueueErrorState(
              message: _provider.errorMessage!,
              onRetry: _provider.load,
            );
          }

          if (queue == null) {
            return _NoQueueState(onRefresh: _provider.load);
          }

          return RefreshIndicator(
            onRefresh: _provider.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                if (_provider.errorMessage != null) ...[
                  _RefreshWarning(message: _provider.errorMessage!),
                  const SizedBox(height: 14),
                ],
                _QueueSummaryCard(
                  queue: queue,
                  position: _provider.position,
                  isLoading: _provider.isLoading,
                ),
                const SizedBox(height: 16),
                _AppointmentCard(
                  appointment: widget.appointment,
                  petName: widget.petName,
                  hospitalName: widget.hospitalName,
                  veterinarianName: widget.veterinarianName,
                  serviceName: widget.serviceName,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pull down to refresh the queue status.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QueueSummaryCard extends StatelessWidget {
  const _QueueSummaryCard({
    required this.queue,
    required this.position,
    required this.isLoading,
  });

  final Queue queue;
  final int? position;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final status = queue.queueStatus;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Queue number',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.deepBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${queue.queueNumber}',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: AppTheme.espresso,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                OwnerQueueStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 18),
            _PositionPanel(
              status: status,
              position: position,
              isLoading: isLoading,
            ),
            if (queue.updatedAt.toLocal().isAfter(DateTime(2000))) ...[
              const SizedBox(height: 14),
              Text(
                'Last updated ${_formatDateTime(queue.updatedAt.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.deepBrown),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '$hour:$minute $period';
  }
}

class _PositionPanel extends StatelessWidget {
  const _PositionPanel({
    required this.status,
    required this.position,
    required this.isLoading,
  });

  final QueueStatus? status;
  final int? position;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = OwnerQueueStatusPresentation.color(status);
    final waitingPosition = position;
    final (title, message) = switch (status) {
      QueueStatus.waiting when waitingPosition != null => (
        'You are number $waitingPosition',
        waitingPosition == 1
            ? 'You are first in the waiting queue.'
            : '${waitingPosition - 1} waiting ${waitingPosition - 1 == 1 ? 'entry is' : 'entries are'} ahead of you.',
      ),
      QueueStatus.waiting when isLoading => (
        'Updating your position',
        'Checking the latest waiting queue.',
      ),
      QueueStatus.waiting => (
        'Waiting position unavailable',
        'Refresh to try again. An unverified position is not shown.',
      ),
      QueueStatus.called => (
        'Please proceed',
        'Your turn has been called. Please go to the consultation room.',
      ),
      QueueStatus.inConsultation => (
        'Consultation in progress',
        'Your pet is currently with the veterinarian.',
      ),
      QueueStatus.completed => (
        'Consultation completed',
        'This queue entry is now complete.',
      ),
      QueueStatus.skipped => (
        'Queue turn skipped',
        'Please contact hospital staff if you still need assistance.',
      ),
      QueueStatus.cancelled => (
        'Queue entry cancelled',
        'This queue entry is no longer active.',
      ),
      null => (
        'Queue status unavailable',
        'Refresh to try again or contact hospital staff.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            OwnerQueueStatusPresentation.icon(status),
            color: color,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.petName,
    required this.hospitalName,
    required this.veterinarianName,
    required this.serviceName,
  });

  final Appointment appointment;
  final String? petName;
  final String? hospitalName;
  final String? veterinarianName;
  final String? serviceName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.pets_outlined,
              label: 'Pet',
              value: petName ?? appointment.petId,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.local_hospital_outlined,
              label: 'Hospital',
              value: hospitalName ?? appointment.hospitalId,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.medical_services_outlined,
              label: 'Service',
              value: serviceName ?? appointment.serviceId,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Veterinarian',
              value: veterinarianName ?? appointment.vetId,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Scheduled',
              value: _formatDateTime(appointment.dateTime),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '$hour:$minute $period';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.deepBrown),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RefreshWarning extends StatelessWidget {
  const _RefreshWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _NoQueueState extends StatelessWidget {
  const _NoQueueState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 64,
              color: AppTheme.deepBrown,
            ),
            const SizedBox(height: 16),
            Text(
              'Not checked in yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Queue details will appear after hospital staff checks in this appointment.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }
}

class _QueueErrorState extends StatelessWidget {
  const _QueueErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
