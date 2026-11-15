import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/hospital_staff/data/repositories/firebase_hospital_staff_assignment_repository.dart';
import '../../features/hospital_staff/domain/repositories/hospital_staff_assignment_repository.dart';
import '../../features/hospital_staff/presentation/widgets/hospital_staff_access_gate.dart';
import '../../features/profile/data/repositories/firebase_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/veterinary/data/repositories/firebase_veterinarian_assignment_repository.dart';
import '../../features/veterinary/domain/entities/veterinarian.dart';
import '../../features/veterinary/domain/repositories/veterinarian_assignment_repository.dart';
import '../../shared/enums/user_role.dart';

/// Authorizes the named scanner route before building camera content.
class QrScannerAccessGate extends StatefulWidget {
  const QrScannerAccessGate({
    super.key,
    required this.auth,
    required this.childBuilder,
    this.profileRepository,
    this.staffAssignmentRepository,
    this.veterinarianAssignmentRepository,
  });

  final FirebaseAuth auth;
  final ProfileRepository? profileRepository;
  final HospitalStaffAssignmentRepository? staffAssignmentRepository;
  final VeterinarianAssignmentRepository? veterinarianAssignmentRepository;
  final Widget Function(BuildContext context, bool verificationOnly)
  childBuilder;

  @override
  State<QrScannerAccessGate> createState() => _QrScannerAccessGateState();
}

class _QrScannerAccessGateState extends State<QrScannerAccessGate> {
  late final ProfileProvider _profiles;
  late final String? _sessionUid;
  late final HospitalStaffAssignmentRepository _staffAssignments;
  StreamSubscription<User?>? _authSubscription;
  String? _observedUid;
  bool _profileStartupFailed = false;
  Future<Veterinarian?>? _veterinarianAssignment;

  @override
  void initState() {
    super.initState();
    _sessionUid = widget.auth.currentUser?.uid;
    _observedUid = _sessionUid;
    _authSubscription = widget.auth.authStateChanges().listen((user) {
      if (mounted) setState(() => _observedUid = user?.uid);
    });
    _staffAssignments =
        widget.staffAssignmentRepository ??
        FirebaseHospitalStaffAssignmentRepository(auth: widget.auth);
    _profiles = ProfileProvider(
      repository:
          widget.profileRepository ??
          FirebaseProfileRepository(auth: widget.auth),
    );
    try {
      _profiles.startListening();
    } catch (_) {
      _profileStartupFailed = true;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _profiles,
    builder: (context, _) {
      if (_sessionUid == null ||
          _observedUid != _sessionUid ||
          widget.auth.currentUser?.uid != _sessionUid) {
        return const _Denied('Scanner access unavailable');
      }
      if (_profileStartupFailed) {
        return const _Denied('Unable to verify scanner access');
      }
      if (_profiles.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (_profiles.errorMessage != null) {
        return const _Denied('Unable to verify scanner access');
      }
      final profile = _profiles.profile;
      if (profile == null || profile.uid != _sessionUid) {
        return const _Denied('Scanner access unavailable');
      }
      final role = UserRoleX.tryParseFirestore(profile.role);
      if (role == UserRole.veterinaryStaff) {
        return HospitalStaffAccessGate(
          repository: _staffAssignments,
          workspaceBuilder: (context, assignment) {
            if (widget.auth.currentUser?.uid != _sessionUid ||
                assignment.userId != _sessionUid) {
              return const _Denied('Scanner access unavailable');
            }
            return widget.childBuilder(context, true);
          },
        );
      }
      if (role == UserRole.veterinarian) {
        _veterinarianAssignment ??=
            (widget.veterinarianAssignmentRepository ??
                    FirebaseVeterinarianAssignmentRepository(auth: widget.auth))
                .getCurrentAssignment();
        return FutureBuilder<Veterinarian?>(
          future: _veterinarianAssignment,
          builder: (context, snapshot) {
            if (widget.auth.currentUser?.uid != _sessionUid) {
              return const _Denied('Scanner access unavailable');
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final assignment = snapshot.data;
            if (snapshot.hasError ||
                assignment == null ||
                !assignment.active ||
                assignment.vetId.trim().isEmpty ||
                assignment.hospitalId.trim().isEmpty ||
                assignment.hospitalId == 'unassigned') {
              return const _Denied('Scanner access unavailable');
            }
            return widget.childBuilder(context, false);
          },
        );
      }
      return const _Denied('Scanner access unavailable');
    },
  );
}

class _Denied extends StatelessWidget {
  const _Denied(this.message);
  final String message;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}
