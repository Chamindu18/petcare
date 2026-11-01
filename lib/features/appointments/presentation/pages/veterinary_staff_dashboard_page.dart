import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_appointment_repository.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/appointment_usecases.dart';
import '../providers/veterinary_appointment_provider.dart';

/// Dashboard for veterinary staff scoped to their assigned hospital.
class VeterinaryStaffDashboardPage extends StatefulWidget {
  const VeterinaryStaffDashboardPage({required this.hospitalId, super.key});

  final String hospitalId;

  @override
  State<VeterinaryStaffDashboardPage> createState() =>
      _VeterinaryStaffDashboardPageState();
}

class _VeterinaryStaffDashboardPageState
    extends State<VeterinaryStaffDashboardPage> {
  late final VeterinaryAppointmentProvider _provider;

  @override
  void initState() {
    super.initState();

    final appointmentRepository = FirebaseAppointmentRepository();

    _provider = VeterinaryAppointmentProvider(
      getAppointmentsByHospital: GetAppointmentsByHospital(
        appointmentRepository,
      ),
      getAppointmentsByVeterinarian: GetAppointmentsByVeterinarian(
        appointmentRepository,
      ),
    );

    _provider.loadForHospital(widget.hospitalId);
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
      appBar: AppBar(title: const Text('Staff Dashboard')),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          if (_provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.errorMessage != null) {
            return _ErrorState(
              message: _provider.errorMessage!,
              onRetry: () => _provider.loadForHospital(widget.hospitalId),
            );
          }

          final appointments = _provider.appointments;

          if (appointments.isEmpty) {
            return const _EmptyState();
          }

          final today = DateTime.now();

          final todaysAppointments = appointments.where(
            (appointment) => _isSameDay(appointment.dateTime, today),
          );

          final pendingCount = appointments
              .where((appointment) => appointment.status == 'pending')
              .length;

          final confirmedCount = appointments
              .where((appointment) => appointment.status == 'confirmed')
              .length;

          final upcomingAppointments =
              appointments
                  .where(
                    (appointment) =>
                        appointment.dateTime.isAfter(today) &&
                        appointment.status != 'cancelled' &&
                        appointment.status != 'rejected',
                  )
                  .toList()
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

          return RefreshIndicator(
            onRefresh: () => _provider.loadForHospital(widget.hospitalId),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  'Appointment Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage appointments for your assigned hospital.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Today',
                        value: todaysAppointments.length.toString(),
                        icon: Icons.today_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pending',
                        value: pendingCount.toString(),
                        icon: Icons.pending_actions_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  title: 'Confirmed',
                  value: confirmedCount.toString(),
                  icon: Icons.event_available_outlined,
                ),

                const SizedBox(height: 28),

                Text(
                  'Upcoming Appointments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),

                if (upcomingAppointments.isEmpty)
                  const _NoUpcomingAppointments()
                else
                  ...upcomingAppointments
                      .take(10)
                      .map(
                        (appointment) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AppointmentCard(appointment: appointment),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 30, color: AppTheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

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
            const SizedBox(height: 14),
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
              value: appointment.petId,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Veterinarian',
              value: appointment.vetId,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 64),
            SizedBox(height: 16),
            Text('No appointments yet', textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Appointments for your hospital will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoUpcomingAppointments extends StatelessWidget {
  const _NoUpcomingAppointments();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No upcoming appointments.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.deepBrown),
        ),
      ),
    );
  }
}

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
