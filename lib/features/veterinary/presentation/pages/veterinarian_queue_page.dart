import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../queue/data/repositories/firebase_queue_repository.dart';
import '../../../queue/domain/entities/queue.dart';
import '../../../queue/domain/repositories/queue_repository.dart';
import '../providers/veterinarian_queue_provider.dart';

/// V05 veterinarian queue, scoped to the verified assigned veterinarian.
class VeterinarianQueuePage extends StatefulWidget {
  const VeterinarianQueuePage({
    super.key,
    required this.hospitalId,
    required this.veterinarianId,
    this.isActive = true,
    this.queueRepository,
    this.now,
  });

  final String hospitalId;
  final String veterinarianId;
  final bool isActive;
  final VeterinarianQueueRepository? queueRepository;
  final DateTime Function()? now;

  @override
  State<VeterinarianQueuePage> createState() => _VeterinarianQueuePageState();
}

class _VeterinarianQueuePageState extends State<VeterinarianQueuePage> {
  VeterinarianQueueProvider? _provider;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _ensureProvider();
  }

  @override
  void didUpdateWidget(covariant VeterinarianQueuePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final assignmentChanged =
        widget.hospitalId != oldWidget.hospitalId ||
        widget.veterinarianId != oldWidget.veterinarianId;
    if (assignmentChanged) {
      _provider?.dispose();
      _provider = null;
      if (widget.isActive) _ensureProvider();
      return;
    }
    if (widget.isActive && !oldWidget.isActive) {
      _ensureProvider();
      _provider?.refresh();
    }
  }

  @override
  void dispose() {
    _provider?.dispose();
    super.dispose();
  }

  void _ensureProvider() {
    if (_provider != null) return;
    if (widget.hospitalId.trim().isEmpty ||
        widget.veterinarianId.trim().isEmpty) {
      return;
    }
    _provider = VeterinarianQueueProvider(
      queueRepository: widget.queueRepository ?? FirebaseQueueRepository(),
      assignedHospitalId: widget.hospitalId,
      assignedVeterinarianId: widget.veterinarianId,
      now: widget.now,
    )..refresh();
  }

  Future<void> _run(Future<bool> Function() command) async {
    await command();
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required String confirmLabel,
    required Future<bool> Function() command,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
      ),
    );
    if (confirmed == true && mounted) await _run(command);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    if (provider == null) {
      return widget.isActive
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final busy = provider.isLoading || provider.isProcessing;
        return SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: provider.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's queue",
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.espresso,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Asia/Colombo · Assigned patients only',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.deepBrown),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh queue',
                      onPressed: busy ? null : provider.refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(color: AppTheme.primary),
                  ),
                if (provider.actionMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      provider.actionMessage!,
                      style: const TextStyle(
                        color: AppTheme.deepBrown,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  _messageCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Queue unavailable',
                    message: provider.errorMessage!,
                    action: TextButton(
                      onPressed: busy ? null : provider.refresh,
                      child: const Text('Try again'),
                    ),
                  ),
                ] else if (!busy && provider.entries.isEmpty)
                  const SizedBox(height: 24)
                else if (!busy)
                  ...provider.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildQueueCard(provider, entry),
                    ),
                  )
                else
                  const SizedBox(height: 24),
                if (provider.errorMessage == null &&
                    !busy &&
                    provider.entries.isEmpty)
                  _messageCard(
                    icon: Icons.event_available_outlined,
                    title: 'No patients in your queue',
                    message: 'Assigned patients checked in by hospital staff will appear here.',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueCard(VeterinarianQueueProvider provider, Queue entry) {
    final status = QueueStatus.tryParse(entry.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${entry.queueNumber}',
                  style: const TextStyle(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusLabel(status, entry.status),
                  style: const TextStyle(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailLine('Pet reference', _shortId(entry.petId)),
          _detailLine('Appointment reference', _shortId(entry.appointmentId)),
          if (status == QueueStatus.waiting && entry.position > 0)
            _detailLine('Queue position', '${entry.position}'),
          const SizedBox(height: 12),
          _buildActions(provider, entry, status),
        ],
      ),
    );
  }

  Widget _buildActions(
    VeterinarianQueueProvider provider,
    Queue entry,
    QueueStatus? status,
  ) {
    if (status == null) {
      return const Text(
        'Unknown status. Refresh before taking action.',
        style: TextStyle(color: AppTheme.error, fontSize: 12),
      );
    }
    if (status.isTerminal) {
      return Text(
        'This queue entry is ${status.value.replaceAll('_', ' ')}.',
        style: const TextStyle(color: AppTheme.deepBrown, fontSize: 12),
      );
    }
    final primaryAction = switch (status) {
      QueueStatus.waiting => FilledButton.icon(
        onPressed: provider.canAct
            ? () => _run(() => provider.callPatient(entry))
            : null,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Call patient'),
      ),
      QueueStatus.called => FilledButton.icon(
        onPressed: provider.canAct
            ? () => _run(() => provider.startConsultation(entry))
            : null,
        icon: const Icon(Icons.play_circle_outline_rounded),
        label: const Text('Start consultation'),
      ),
      QueueStatus.inConsultation => FilledButton.icon(
        onPressed: provider.canAct
            ? () => _run(() => provider.completeConsultation(entry))
            : null,
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('Complete consultation'),
      ),
      QueueStatus.completed ||
      QueueStatus.skipped ||
      QueueStatus.cancelled => const SizedBox.shrink(),
    };
    final canSkip =
        status == QueueStatus.waiting || status == QueueStatus.called;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        primaryAction,
        if (canSkip)
          OutlinedButton(
            onPressed: provider.canAct
                ? () => _confirmAndRun(
                    title: 'Skip patient?',
                    message: 'The patient will be marked as skipped and cannot be reopened.',
                    confirmLabel: 'Skip',
                    command: () => provider.skip(entry),
                    destructive: true,
                  )
                : null,
            child: const Text('Skip'),
          ),
        TextButton(
          onPressed: provider.canAct
              ? () => _confirmAndRun(
                  title: 'Cancel queue entry?',
                  message: 'The queue entry will be cancelled and cannot be reopened.',
                  confirmLabel: 'Cancel entry',
                  command: () => provider.cancel(entry),
                  destructive: true,
                )
              : null,
          style: TextButton.styleFrom(foregroundColor: AppTheme.error),
          child: const Text('Cancel entry'),
        ),
      ],
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: AppTheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.deepBrown,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.deepBrown,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.espresso, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(QueueStatus? status, String fallback) {
    return switch (status) {
      QueueStatus.waiting => 'Waiting',
      QueueStatus.called => 'Called',
      QueueStatus.inConsultation => 'In consultation',
      QueueStatus.completed => 'Completed',
      QueueStatus.skipped => 'Skipped',
      QueueStatus.cancelled => 'Cancelled',
      null => 'Unknown status: $fallback',
    };
  }

  String _shortId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Unknown';
    return trimmed.length <= 10
        ? trimmed.toUpperCase()
        : trimmed.substring(0, 10).toUpperCase();
  }
}
