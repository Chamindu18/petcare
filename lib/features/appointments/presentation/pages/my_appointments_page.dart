import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../qr_health_passport/presentation/pages/owner_qr_health_passport_page.dart';
import '../../../queue/domain/entities/queue.dart';
import '../../../queue/domain/repositories/queue_repository.dart';
import '../../../queue/presentation/pages/owner_queue_details_page.dart';
import '../../../queue/presentation/widgets/owner_queue_status_badge.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointment_provider.dart';

///  Shows the signed-in owner's appointments.
class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({
    required this.provider,
    this.queueRepository,
    this.ownerQueueRepository,
    super.key,
  });

  final AppointmentProvider provider;
  final QueueRepository? queueRepository;
  final OwnerQueueRepository? ownerQueueRepository;

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  @override
  void initState() {
    super.initState();

    // Load appointments when the page opens.
    widget.provider.loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('My Appointments')),
      body: AnimatedBuilder(
        animation: widget.provider,
        builder: (context, _) {
          // Show loading state.
          if (widget.provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error state with retry.
          if (widget.provider.errorMessage != null) {
            return _ErrorState(
              message: widget.provider.errorMessage!,
              onRetry: widget.provider.loadAppointments,
            );
          }

          // Show empty state.
          if (widget.provider.appointments.isEmpty) {
            return const _EmptyState();
          }

          // Show the owner's appointments.
          return RefreshIndicator(
            onRefresh: widget.provider.loadAppointments,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              itemCount: widget.provider.appointments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final appointment = widget.provider.appointments[index];

                return _AppointmentCard(
                  appointment: appointment,
                  provider: widget.provider,
                  queueRepository: widget.queueRepository,
                  ownerQueueRepository: widget.ownerQueueRepository,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Displays one appointment summary.
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.provider,
    required this.queueRepository,
    required this.ownerQueueRepository,
  });

  final Appointment appointment;
  final AppointmentProvider provider;
  final QueueRepository? queueRepository;
  final OwnerQueueRepository? ownerQueueRepository;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Appointment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatDate(appointment.dateTime),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: 'Time',
              value: _formatTime(appointment.dateTime),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.pets_outlined,
              label: 'Pet',
              value:
                  provider.getPet(appointment.petId)?.name ?? appointment.petId,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.local_hospital_outlined,
              label: 'Hospital',
              value:
                  provider.getHospital(appointment.hospitalId)?.name ??
                  appointment.hospitalId,
            ),

            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.medical_services_outlined,
              label: 'Service',
              value:
                  provider.getService(appointment.serviceId)?.name ??
                  appointment.serviceId,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Veterinarian',
              value:
                  provider.getVeterinarian(appointment.vetId)?.name ??
                  appointment.vetId,
            ),
            if (appointment.reason.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.notes_outlined,
                label: 'Reason',
                value: appointment.reason,
              ),
            ],
            if (appointment.status.trim().toLowerCase() == 'confirmed') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.ownerQrHealthPassport,
                    arguments: OwnerQrHealthPassportArgs(
                      petId: appointment.petId,
                      petName:
                          provider.getPet(appointment.petId)?.name ?? 'Pet',
                      appointmentId: appointment.appointmentId,
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Show QR Health Passport'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _QueueSection(
              appointment: appointment,
              provider: provider,
              queue: provider.getQueueForAppointment(appointment.appointmentId),
              queueRepository: queueRepository,
              ownerQueueRepository: ownerQueueRepository,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

/// Displays the owner's linked queue summary without inventing a position.
class _QueueSection extends StatelessWidget {
  const _QueueSection({
    required this.appointment,
    required this.provider,
    required this.queue,
    required this.queueRepository,
    required this.ownerQueueRepository,
  });

  final Appointment appointment;
  final AppointmentProvider provider;
  final Queue? queue;
  final QueueRepository? queueRepository;
  final OwnerQueueRepository? ownerQueueRepository;

  @override
  Widget build(BuildContext context) {
    final queueId = appointment.queueId?.trim() ?? '';
    if (queueId.isEmpty) {
      return const _QueueNotice(
        icon: Icons.hourglass_empty_rounded,
        message: 'Queue details will appear after hospital staff checks in.',
      );
    }

    final linkedQueue = queue;
    if (linkedQueue == null) {
      return const _QueueNotice(
        icon: Icons.info_outline,
        message: 'Queue information is unavailable. Pull down to refresh.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Queue status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OwnerQueueStatusBadge(status: linkedQueue.queueStatus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Queue number: ${linkedQueue.queueNumber}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.deepBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (queueRepository != null && ownerQueueRepository != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openQueue(context, linkedQueue),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View queue'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openQueue(BuildContext context, Queue linkedQueue) {
    final queueRepo = queueRepository;
    final ownerRepo = ownerQueueRepository;
    if (queueRepo == null || ownerRepo == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerQueueDetailsPage(
          appointment: appointment,
          queueRepository: queueRepo,
          ownerQueueRepository: ownerRepo,
          initialQueue: linkedQueue,
          petName: provider.getPet(appointment.petId)?.name,
          hospitalName: provider.getHospital(appointment.hospitalId)?.name,
          veterinarianName: provider.getVeterinarian(appointment.vetId)?.name,
          serviceName: provider.getService(appointment.serviceId)?.name,
        ),
      ),
    );
  }
}

class _QueueNotice extends StatelessWidget {
  const _QueueNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.deepBrown),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown),
          ),
        ),
      ],
    );
  }
}

/// Displays appointment status.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppTheme.deepBrown, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Empty state shown when no appointments exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: AppTheme.deepBrown,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booked appointments will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state with retry action.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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

/// Reusable row for appointment information.
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
