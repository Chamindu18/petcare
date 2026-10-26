import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointment_provider.dart';

///  Shows the signed-in owner's appointments.
class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({required this.provider, super.key});

  final AppointmentProvider provider;

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
  const _AppointmentCard({required this.appointment, required this.provider});

  final Appointment appointment;
  final AppointmentProvider provider;

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
