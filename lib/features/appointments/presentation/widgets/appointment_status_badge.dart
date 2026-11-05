import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class AppointmentStatusBadge extends StatelessWidget {
  const AppointmentStatusBadge({super.key, required this.status});

  final String status;

  Color get _color {
    return switch (status.trim().toLowerCase()) {
      'confirmed' || 'completed' => AppTheme.success,
      'pending' => AppTheme.warning,
      'cancelled' || 'rejected' => AppTheme.error,
      _ => AppTheme.information,
    };
  }

  @override
  Widget build(BuildContext context) {
    final label = status.trim().isEmpty ? 'UNKNOWN' : status.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
