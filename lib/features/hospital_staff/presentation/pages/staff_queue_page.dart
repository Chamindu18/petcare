import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../appointments/data/repositories/firebase_appointment_repository.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../queue/data/repositories/firebase_queue_repository.dart';
import '../../../queue/domain/repositories/queue_repository.dart';
import '../providers/staff_queue_provider.dart';

/// V05 staff queue. Hospital ID originates exclusively from the staff shell.
class StaffQueuePage extends StatefulWidget {
  const StaffQueuePage({
    super.key,
    required this.hospitalId,
    this.appointmentRepository,
    this.queueRepository,
    this.isActive = true,
    this.onQueueChanged,
  });
  final String hospitalId;
  final bool isActive;
  final VoidCallback? onQueueChanged;
  final AppointmentRepository? appointmentRepository;
  final StaffQueueCommandRepository? queueRepository;
  @override
  State<StaffQueuePage> createState() => _StaffQueuePageState();
}

class _StaffQueuePageState extends State<StaffQueuePage>
    with WidgetsBindingObserver {
  late final StaffQueueProvider _provider;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = StaffQueueProvider(
      appointmentRepository:
          widget.appointmentRepository ?? FirebaseAppointmentRepository(),
      queueRepository: widget.queueRepository ?? FirebaseQueueRepository(),
      assignedHospitalId: widget.hospitalId,
    )..refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StaffQueuePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _provider.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _provider.refresh();
    }
  }

  Future<void> _run(Future<bool> Function() command) async {
    if (await command() && mounted) widget.onQueueChanged?.call();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final busy = _provider.isLoading || _provider.isProcessing;
        return RefreshIndicator(
          onRefresh: _provider.refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Today\'s Queue',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.deepBrown,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh queue',
                    onPressed: busy ? null : _provider.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const Text('Hospital day: Asia/Colombo'),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              if (_provider.actionMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _provider.actionMessage!,
                    semanticsLabel: _provider.actionMessage,
                  ),
                ),
              if (_provider.errorMessage != null) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.primary,
                ),
                Text(_provider.errorMessage!),
                TextButton(
                  onPressed: busy ? null : _provider.refresh,
                  child: const Text('Try Again'),
                ),
              ] else ...[
                const SizedBox(height: 20),
                Text(
                  'Ready for check-in',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!busy && _provider.eligibleAppointments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No confirmed appointments eligible for check-in today.',
                    ),
                  ),
                for (final appointment in _provider.eligibleAppointments)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pet: ${appointment.petId}'),
                          Text('Appointment: ${appointment.appointmentId}'),
                          Text('Reason: ${appointment.reason}'),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _provider.canAct
                                ? () =>
                                      _run(() => _provider.checkIn(appointment))
                                : null,
                            child: const Text('Check In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Hospital queue',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!busy && _provider.entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No patients checked in today.'),
                  ),
                for (final entry in _provider.entries)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Queue #${entry.queueNumber}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('Pet: ${entry.petId}'),
                          Text('Appointment: ${entry.appointmentId}'),
                          Text(switch (entry.status) {
                            'waiting' => 'Waiting',
                            'in_consultation' => 'In consultation',
                            'completed' => 'Completed',
                            _ => 'Unknown status: refresh required',
                          }),
                          if ([
                            'waiting',
                            'in_consultation',
                          ].contains(entry.status))
                            FilledButton(
                              onPressed: _provider.canAct
                                  ? () => _run(() => _provider.advance(entry))
                                  : null,
                              child: Text(
                                entry.status == 'waiting'
                                    ? 'Start Consultation'
                                    : 'Complete Consultation',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
