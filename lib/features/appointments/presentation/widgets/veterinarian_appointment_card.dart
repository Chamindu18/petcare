import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/appointment.dart';
import 'appointment_status_badge.dart';

class VeterinarianAppointmentCard extends StatelessWidget {
  const VeterinarianAppointmentCard({
    super.key,
    required this.appointment,
    required this.serviceName,
    this.onTap,
  });

  final Appointment appointment;
  final String? serviceName;
  final VoidCallback? onTap;

  String get _shortPetId {
    final id = appointment.petId.trim();

    if (id.isEmpty) return 'Unknown';
    return id.length <= 7 ? id.toUpperCase() : id.substring(0, 7).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = appointment.dateTime.toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final time = TimeOfDay.fromDateTime(dateTime).format(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatSchedule(dateTime, time),
                          style: const TextStyle(
                            color: AppTheme.espresso,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          serviceName?.trim().isNotEmpty == true
                              ? serviceName!.trim()
                              : 'Service information unavailable',
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
                  AppointmentStatusBadge(status: appointment.status),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppTheme.deepBrown,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Pet details restricted · ref $_shortPetId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.deepBrown.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.deepBrown,
                      size: 20,
                    ),
                ],
              ),
              if (appointment.reason.trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  appointment.reason.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.deepBrown,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatSchedule(DateTime dateTime, String time) {
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today · $time';
    }

    if (date == today.add(const Duration(days: 1))) {
      return 'Tomorrow · $time';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} · $time';
  }
}
