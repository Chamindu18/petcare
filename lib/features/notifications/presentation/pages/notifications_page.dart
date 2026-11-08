import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/router/app_router.dart';
import '../../data/repositories/firebase_notification_repository.dart';
import '../../domain/entities/notification.dart' as notification_entity;
import '../providers/notification_provider.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.notificationRepository,
    this.onOpenAppointment,
    this.onOpenAppointmentById,
    this.onOpenQueue,
  });

  final NotificationRepository? notificationRepository;
  final VoidCallback? onOpenAppointment;
  final ValueChanged<String>? onOpenAppointmentById;
  final VoidCallback? onOpenQueue;
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationProvider _notificationProvider;

  @override
  void initState() {
    super.initState();

    _notificationProvider = NotificationProvider(
      repository:
          widget.notificationRepository ?? FirebaseNotificationRepository(),
    );

    _notificationProvider.startListening();
  }

  @override
  void dispose() {
    _notificationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          ListenableBuilder(
            listenable: _notificationProvider,
            builder: (context, _) {
              if (_notificationProvider.unreadCount == 0) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: _notificationProvider.markAllAsRead,
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _notificationProvider,
        builder: (context, _) {
          if (_notificationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_notificationProvider.errorMessage != null) {
            return _ErrorState(onRetry: _notificationProvider.startListening);
          }

          if (_notificationProvider.notifications.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: _notificationProvider.notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = _notificationProvider.notifications[index];

              return _NotificationCard(
                notification: notification,
                onTap: () async {
                  await _notificationProvider.markAsRead(
                    notification.notificationId,
                  );
                  if (!context.mounted) return;
                  if (notification.targetType == 'queue' &&
                      widget.onOpenQueue != null) {
                    widget.onOpenQueue!();
                    return;
                  }
                  if (notification.targetType == 'appointment') {
                    if (widget.onOpenAppointmentById != null) {
                      widget.onOpenAppointmentById!(notification.targetId);
                      return;
                    }
                    if (widget.onOpenAppointment != null) {
                      widget.onOpenAppointment!();
                      return;
                    }
                  }
                  final route = switch (notification.targetType) {
                    'appointment' || 'queue' => AppRouter.myAppointments,
                    'adoption_request'
                        when notification.type ==
                                'adoption_request_submitted' ||
                            notification.type == 'adoption_request_withdrawn' =>
                      AppRouter.adoptionRequests,
                    'adoption_request' => AppRouter.myAdoptionRequests,
                    _ => null,
                  };
                  if (route != null) Navigator.of(context).pushNamed(route);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final notification_entity.Notification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.read
                      ? AppTheme.background
                      : AppTheme.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.deepBrown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(notification.type),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: notification.read
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: notification.read
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                    if (notification.appointmentTime case final time?) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled: ${time.toLocal().day}/${time.toLocal().month}/${time.toLocal().year} '
                        '${time.toLocal().hour.toString().padLeft(2, '0')}:'
                        '${time.toLocal().minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                    if (notification.queueNumber case final number?) ...[
                      const SizedBox(height: 4),
                      Text('Queue number: $number'),
                    ],
                    if (notification.listingName case final name?) ...[
                      const SizedBox(height: 4),
                      Text('Listing: $name'),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.deepBrown),
                    ),
                  ],
                ),
              ),
              if (!notification.read) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(String type) => switch (type) {
    'appointment_requested' => 'New appointment request',
    'appointment_assigned' => 'New appointment assigned',
    'appointment_reassigned' => 'Appointment reassigned',
    'appointment_unassigned' => 'Appointment removed',
    'appointment_cancelled_veterinarian' => 'Appointment cancelled',
    'appointment_confirmed' => 'Appointment confirmed',
    'appointment_rejected' => 'Appointment rejected',
    'queue_checked_in' => 'Queue check-in',
    'patient_checked_in' => 'Patient checked in',
    'queue_called' => 'Called to consultation',
    'queue_in_consultation' => 'Consultation started',
    'queue_completed' => 'Consultation completed',
    'queue_skipped' => 'Queue entry skipped',
    'queue_cancelled' => 'Queue entry cancelled',
    'adoption_accepted' => 'Adoption request accepted',
    'adoption_rejected' => 'Adoption request rejected',
    'adoption_request_submitted' => 'New adoption request',
    'adoption_request_withdrawn' => 'Adoption request withdrawn',
    _ => 'Notification',
  };

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You’re all caught up. New updates will appear here.',
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
