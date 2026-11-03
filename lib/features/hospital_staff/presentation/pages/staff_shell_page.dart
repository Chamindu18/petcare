import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../hospitals/domain/repositories/hospital_repository.dart';
import '../../domain/entities/hospital_staff_assignment.dart';
import 'staff_appointments_page.dart';
import 'staff_hospital_overview_page.dart';

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
  });

  final HospitalStaffAssignment assignment;
  final HospitalRepository? hospitalRepository;
  final AppointmentRepository? appointmentRepository;

  @override
  State<StaffShellPage> createState() => _StaffShellPageState();
}

class _StaffShellPageState extends State<StaffShellPage> {
  int _currentIndex = 0;

  // Recreates the Overview page when staff return to it, allowing
  // appointment statistics to reflect changes made in other tabs.
  int _overviewRevision = 0;

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
      // Refresh operational statistics when returning to Overview.
      // Other tab states remain preserved by IndexedStack.
      if (index == 0) {
        _overviewRevision++;
      }

      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;

    final pages = [
      StaffHospitalOverviewPage(
        key: ValueKey('${assignment.hospitalId}-overview-$_overviewRevision'),
        hospitalId: assignment.hospitalId,
        repository: widget.hospitalRepository,
        appointmentRepository: widget.appointmentRepository,
        onOpenAppointments: () => _onTabSelected(1),
      ),
      StaffAppointmentsPage(
        hospitalId: assignment.hospitalId,
        repository: widget.appointmentRepository,
      ),
      const _StaffSectionPage(
        icon: Icons.event_note_rounded,
        title: 'Daily Schedule',
        description:
            'View the hospital schedule and appointments grouped '
            'by veterinarian and date.',
      ),
      const _StaffSectionPage(
        icon: Icons.groups_rounded,
        title: 'Queue Management',
        description:
            'Manage patient check-ins, queue numbers, '
            'and consultation progress.',
      ),
      _StaffProfilePage(hospitalId: assignment.hospitalId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: Text(_navigationItems[_currentIndex].label),
        elevation: 0,
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

/// Temporary placeholder for staff workflow sections not yet implemented.
class _StaffSectionPage extends StatelessWidget {
  const _StaffSectionPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

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
              const Text(
                'This section is under development.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Temporary staff profile until the dedicated profile task is implemented.
class _StaffProfilePage extends StatelessWidget {
  const _StaffProfilePage({required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Staff Profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View your hospital assignment and account information.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              tileColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: const Icon(
                Icons.local_hospital_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('Assigned Hospital'),
              subtitle: Text(hospitalId),
            ),
            const SizedBox(height: 12),
            Text(
              'Account profile settings will be connected in a later task.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
            ),
          ],
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
