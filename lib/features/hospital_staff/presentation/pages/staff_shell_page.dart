import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/hospital_staff_assignment.dart';

/// Main navigation shell for an authenticated hospital staff member.
///
/// Access to this page must be controlled by HospitalStaffAccessGate.
class StaffShellPage extends StatefulWidget {
  const StaffShellPage({super.key, required this.assignment});

  final HospitalStaffAssignment assignment;

  @override
  State<StaffShellPage> createState() => _StaffShellPageState();
}

class _StaffShellPageState extends State<StaffShellPage> {
  int _currentIndex = 0;

  static const List<_StaffNavItem> _navigationItems = [
    _StaffNavItem(label: 'Overview', icon: Icons.dashboard_rounded),
    _StaffNavItem(label: 'Appointments', icon: Icons.calendar_month_rounded),
    _StaffNavItem(label: 'Schedule', icon: Icons.event_note_rounded),
    _StaffNavItem(label: 'Queue', icon: Icons.groups_rounded),
    _StaffNavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;

    final pages = [
      _StaffOverviewPage(hospitalId: assignment.hospitalId),
      const _StaffSectionPage(
        icon: Icons.calendar_month_rounded,
        title: 'Appointments',
        description:
            'Review appointment requests, manage confirmations, '
            'and monitor hospital appointments.',
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

class _StaffOverviewPage extends StatelessWidget {
  const _StaffOverviewPage({required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hospital Workspace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your hospital operations from one place.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_hospital_rounded,
                        color: AppTheme.primary,
                        size: 25,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Assigned Hospital',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hospitalId,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are accessing the workspace assigned '
                    'to your staff account.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.deepBrown.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hospital Operations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 12),
            const _OperationShortcut(
              icon: Icons.calendar_month_rounded,
              title: 'Appointments',
              description: 'Review and manage appointment requests.',
            ),
            const SizedBox(height: 12),
            const _OperationShortcut(
              icon: Icons.event_note_rounded,
              title: 'Daily Schedule',
              description: 'Monitor veterinarian schedules.',
            ),
            const SizedBox(height: 12),
            const _OperationShortcut(
              icon: Icons.groups_rounded,
              title: 'Queue Management',
              description: 'Monitor check-ins and consultation queues.',
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationShortcut extends StatelessWidget {
  const _OperationShortcut({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
