import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/queue_status.dart';

/// Owner-facing label and color for one queue lifecycle state.
abstract final class OwnerQueueStatusPresentation {
  static String label(QueueStatus? status) {
    return switch (status) {
      QueueStatus.waiting => 'Waiting for your turn',
      QueueStatus.called => 'Your turn has been called',
      QueueStatus.inConsultation => 'Consultation in progress',
      QueueStatus.completed => 'Consultation completed',
      QueueStatus.skipped => 'Your queue turn was skipped',
      QueueStatus.cancelled => 'Queue entry cancelled',
      null => 'Queue status unavailable',
    };
  }

  static Color color(QueueStatus? status) {
    return switch (status) {
      QueueStatus.waiting => AppTheme.information,
      QueueStatus.called => AppTheme.warning,
      QueueStatus.inConsultation => AppTheme.primary,
      QueueStatus.completed => AppTheme.success,
      QueueStatus.skipped => AppTheme.warning,
      QueueStatus.cancelled => AppTheme.error,
      null => AppTheme.deepBrown,
    };
  }

  static IconData icon(QueueStatus? status) {
    return switch (status) {
      QueueStatus.waiting => Icons.hourglass_top_rounded,
      QueueStatus.called => Icons.campaign_outlined,
      QueueStatus.inConsultation => Icons.medical_services_outlined,
      QueueStatus.completed => Icons.check_circle_outline,
      QueueStatus.skipped => Icons.skip_next_outlined,
      QueueStatus.cancelled => Icons.cancel_outlined,
      null => Icons.help_outline,
    };
  }
}

class OwnerQueueStatusBadge extends StatelessWidget {
  const OwnerQueueStatusBadge({required this.status, super.key});

  final QueueStatus? status;

  @override
  Widget build(BuildContext context) {
    final color = OwnerQueueStatusPresentation.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            OwnerQueueStatusPresentation.icon(status),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              OwnerQueueStatusPresentation.label(status),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
