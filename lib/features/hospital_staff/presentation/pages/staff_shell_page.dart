import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../hospitals/domain/repositories/hospital_repository.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../queue/domain/repositories/queue_repository.dart';
import '../../domain/entities/hospital_staff_assignment.dart';
import 'staff_appointments_page.dart';
import 'staff_hospital_overview_page.dart';
import 'staff_profile_page.dart';
import 'staff_queue_page.dart';

/// Main navigation shell for an authenticated hospital staff member.
///
/// Access to this page must be controlled by HospitalStaffAccessGate.
/// The hospital ID must originate from the verified staff assignment.
class StaffShellPage extends StatefulWidget {
  const StaffShellPage({
    super.key,
    required this.assignment,
    this.hospitalRepository,
    this.appointmentRepository,
    this.profileRepository,
    this.authRepository,
    this.queueRepository,
  });

  final HospitalStaffAssignment assignment;
  final HospitalRepository? hospitalRepository;
  final AppointmentRepository? appointmentRepository;
  final ProfileRepository? profileRepository;
  final AuthRepository? authRepository;
  final StaffQueueCommandRepository? queueRepository;

  @override
  State<StaffShellPage> createState() => _StaffShellPageState();
}

class _StaffShellPageState extends State<StaffShellPage> {
  int _currentIndex = 0;
  int _overviewRevision = 0;
  int _appointmentsRevision = 0;

  // Avoid starting profile-related Firebase reads until the Profile tab
  // has actually been opened. Keep it mounted afterward using IndexedStack.
  bool _hasOpenedProfile = false;
  bool _hasOpenedQueue = false;

  static const List<_StaffNavItem> _navigationItems = [
    _StaffNavItem(label: 'Overview', icon: Icons.dashboard_rounded),
    _StaffNavItem(label: 'Appointments', icon: Icons.calendar_month_rounded),
    _StaffNavItem(label: 'Schedule', icon: Icons.event_note_rounded),
    _StaffNavItem(label: 'Queue', icon: Icons.groups_rounded),
    _StaffNavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  void _onTabSelected(int index) {
    if (index < 0 || index >= _navigationItems.length) return;
    if (_currentIndex == index) return;

    setState(() {
      // Refresh appointment statistics when returning to Overview.
      // Other tab states remain preserved by IndexedStack.
      if (index == 0) {
        _overviewRevision++;
      }

      if (index == 1) _appointmentsRevision++;
      if (index == 3) _hasOpenedQueue = true;
      if (index == 4) {
        _hasOpenedProfile = true;
      }

      _currentIndex = index;
    });
  }

  @override
  void didUpdateWidget(covariant StaffShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A changed verified assignment represents a different hospital
    // workspace. Reset navigation state rather than retaining old tabs.
    if (oldWidget.assignment.userId != widget.assignment.userId ||
        oldWidget.assignment.hospitalId != widget.assignment.hospitalId) {
      _currentIndex = 0;
      _overviewRevision++;
      _hasOpenedProfile = false;
      _hasOpenedQueue = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;

    final pages = <Widget>[
      StaffHospitalOverviewPage(
        key: ValueKey('${assignment.hospitalId}-overview-$_overviewRevision'),
        hospitalId: assignment.hospitalId,
        repository: widget.hospitalRepository,
        appointmentRepository: widget.appointmentRepository,
        onOpenAppointments: () => _onTabSelected(1),
      ),
      StaffAppointmentsPage(
        key: ValueKey(
          'staff-appointments-${assignment.hospitalId}-$_appointmentsRevision',
        ),
        hospitalId: assignment.hospitalId,
        repository: widget.appointmentRepository,
      ),
      _StaffSectionPage(
        icon: Icons.event_note_rounded,
        title: 'Daily Schedule',
        description:
            'Use the appointment date filter to view the hospital schedule.',
        onOpenAppointments: () => _onTabSelected(1),
      ),
      if (_hasOpenedQueue)
        StaffQueuePage(
          key: ValueKey(
            'staff-queue-${assignment.userId}-${assignment.hospitalId}',
          ),
          hospitalId: assignment.hospitalId,
          appointmentRepository: widget.appointmentRepository,
          queueRepository: widget.queueRepository,
          isActive: _currentIndex == 3,
          onQueueChanged: () => setState(() => _appointmentsRevision++),
        )
      else
        const SizedBox.shrink(),
      if (_hasOpenedProfile)
        StaffProfilePage(
          key: ValueKey(
            'staff-profile-${assignment.userId}-${assignment.hospitalId}',
          ),
          hospitalId: assignment.hospitalId,
          profileRepository: widget.profileRepository,
          hospitalRepository: widget.hospitalRepository,
          authRepository: widget.authRepository,
        )
      else
        const SizedBox.shrink(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: Text(_navigationItems[_currentIndex].label),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsPage(
                  onOpenAppointment: () {
                    Navigator.of(context).pop();
                    _onTabSelected(1);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _StaffBottomNavigation(
        currentIndex: _currentIndex,
        onSelected: _onTabSelected,
        items: _navigationItems,
      ),
    );
  }
}

class _StaffSectionPage extends StatelessWidget {
  const _StaffSectionPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.onOpenAppointments,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onOpenAppointments;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: AppTheme.primary),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepBrown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.deepBrown.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onOpenAppointments,
                child: const Text('Open appointments'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffBottomNavigation extends StatelessWidget {
  const _StaffBottomNavigation({
    required this.currentIndex,
    required this.onSelected,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<_StaffNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.white,
            border: Border(
              top: BorderSide(
                color: AppTheme.secondary.withValues(alpha: 0.22),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _StaffNavigationItem(
                  item: items[index],
                  selected: currentIndex == index,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StaffNavigationItem extends StatelessWidget {
  const _StaffNavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _StaffNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppTheme.primary
        : AppTheme.deepBrown.withValues(alpha: 0.65);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, size: 22, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffNavItem {
  const _StaffNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
