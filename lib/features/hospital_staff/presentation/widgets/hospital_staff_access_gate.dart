import 'package:flutter/material.dart';

import '../../domain/entities/hospital_staff_assignment.dart';
import '../../domain/repositories/hospital_staff_assignment_repository.dart';

typedef HospitalStaffWorkspaceBuilder = Widget Function(
  BuildContext context,
  HospitalStaffAssignment assignment,
);

/// Verifies a staff member's hospital assignment before opening the
/// hospital staff workspace.
class HospitalStaffAccessGate extends StatefulWidget {
  const HospitalStaffAccessGate({
    super.key,
    required this.repository,
    required this.workspaceBuilder,
  });

  final HospitalStaffAssignmentRepository repository;
  final HospitalStaffWorkspaceBuilder workspaceBuilder;

  @override
  State<HospitalStaffAccessGate> createState() =>
      _HospitalStaffAccessGateState();
}

class _HospitalStaffAccessGateState extends State<HospitalStaffAccessGate> {
  late Stream<HospitalStaffAssignment?> _assignmentStream;

  @override
  void initState() {
    super.initState();
    _listenToAssignment();
  }

  @override
  void didUpdateWidget(covariant HospitalStaffAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.repository != widget.repository) {
      _listenToAssignment();
    }
  }

  void _listenToAssignment() {
    _assignmentStream = widget.repository.watchCurrentAssignment();
  }

  void _retry() {
    setState(_listenToAssignment);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HospitalStaffAssignment?>(
      stream: _assignmentStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildMessagePage(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to verify hospital access',
            message:
                'Your hospital assignment could not be verified. '
                'Check your internet connection and try again.',
            actionLabel: 'Retry',
            onAction: _retry,
          );
        }

        final assignment = snapshot.data;

        if (assignment == null ||
            !assignment.hasValidHospitalAccess) {
          return _buildMessagePage(
            icon: Icons.lock_outline,
            title: 'Hospital access unavailable',
            message:
                'Your staff account does not have an active hospital '
                'assignment. Please contact your administrator.',
            actionLabel: 'Check Again',
            onAction: _retry,
          );
        }

        return widget.workspaceBuilder(context, assignment);
      },
    );
  }

  Widget _buildMessagePage({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 56,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}