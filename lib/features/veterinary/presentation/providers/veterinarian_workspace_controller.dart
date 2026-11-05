import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../appointments/data/repositories/firebase_appointment_repository.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/usecases/appointment_usecases.dart';
import '../../../hospitals/data/repositories/firebase_hospital_repository.dart';
import '../../../hospitals/domain/entities/hospital.dart';
import '../../../hospitals/domain/usecases/hospital_usecases.dart';
import '../../../services/data/repositories/firebase_service_repository.dart';
import '../../../services/domain/entities/service.dart';
import '../../../services/domain/usecases/service_usecases.dart';
import '../../data/repositories/cloudinary_veterinarian_image_repository.dart';
import '../../data/repositories/firebase_veterinarian_assignment_repository.dart';
import '../../data/repositories/firebase_veterinarian_repository.dart';
import '../../domain/entities/veterinarian.dart';
import '../../domain/repositories/veterinarian_image_repository.dart';
import '../../domain/usecases/get_current_veterinarian_assignment.dart';
import '../../domain/usecases/veterinarian_usecases.dart';

class VeterinarianWorkspaceController extends ChangeNotifier {
  VeterinarianWorkspaceController({
    required this._getAssignment,
    required this._getAppointments,
    required this._getHospital,
    required this._getServices,
    required this._confirmAppointment,
    required this._rejectAppointment,
    required this._updateVeterinarianProfile,
    required this._imageRepository,
    FirebaseAuth? auth,
  }) : _auth = auth {
    _sessionUid = auth?.currentUser?.uid;
    _authSubscription = auth?.authStateChanges().listen((user) {
      if (user?.uid != _sessionUid) invalidateSession();
    });
  }

  factory VeterinarianWorkspaceController.production() {
    final appointmentRepository = FirebaseAppointmentRepository();

    return VeterinarianWorkspaceController(
      getAssignment: GetCurrentVeterinarianAssignment(
        FirebaseVeterinarianAssignmentRepository(),
      ),
      getAppointments: GetAppointmentsByVeterinarian(appointmentRepository),
      getHospital: GetHospitalById(FirebaseHospitalRepository()),
      getServices: GetServicesByHospital(FirebaseServiceRepository()),
      confirmAppointment: ConfirmAppointment(appointmentRepository),
      rejectAppointment: RejectAppointment(appointmentRepository),
      updateVeterinarianProfile: UpdateVeterinarianProfile(
        FirebaseVeterinarianRepository(),
      ),
      imageRepository: CloudinaryVeterinarianImageRepository(),
      auth: FirebaseAuth.instance,
    );
  }

  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSubscription;
  String? _sessionUid;
  int _generation = 0;
  int _sessionRevision = 0;
  int get sessionRevision => _sessionRevision;
  String? _hospitalWarning;
  String? get hospitalWarning => _hospitalWarning;

  bool _current(int generation) =>
      !_isDisposed &&
      generation == _generation &&
      (_auth == null ||
          (_sessionUid != null && _auth.currentUser?.uid == _sessionUid));

  void invalidateSession() {
    _sessionRevision++;
    _generation++;
    _veterinarian = null;
    _hospital = null;
    _appointments = [];
    _serviceNames = {};
    _processingAppointmentIds.clear();
    _isLoading = false;
    _isSavingProfile = false;
    _isUploadingImage = false;
    _loadErrorMessage = 'Your session changed. Please sign in again.';
    _notify();
  }

  void bindSession(String uid) {
    if (_auth == null || uid == _sessionUid) return;
    invalidateSession();
    _sessionUid = uid;
  }

  DateTime _sriLanka(DateTime value) =>
      value.toUtc().add(const Duration(hours: 5, minutes: 30));

  final GetCurrentVeterinarianAssignment _getAssignment;
  final GetAppointmentsByVeterinarian _getAppointments;
  final GetHospitalById _getHospital;
  final GetServicesByHospital _getServices;
  final ConfirmAppointment _confirmAppointment;
  final RejectAppointment _rejectAppointment;
  final UpdateVeterinarianProfile _updateVeterinarianProfile;
  final VeterinarianImageRepository _imageRepository;

  Veterinarian? _veterinarian;
  Hospital? _hospital;
  List<Appointment> _appointments = [];
  Map<String, String> _serviceNames = {};

  final Set<String> _processingAppointmentIds = {};

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isUploadingImage = false;
  bool _isDisposed = false;

  String? _loadErrorMessage;
  String? _actionErrorMessage;
  String? _profileErrorMessage;

  Veterinarian? get veterinarian => _veterinarian;
  Hospital? get hospital => _hospital;
  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  bool get isSavingProfile => _isSavingProfile;
  bool get isUploadingImage => _isUploadingImage;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  String? get profileErrorMessage => _profileErrorMessage;

  bool isProcessingAppointment(String appointmentId) {
    return _processingAppointmentIds.contains(appointmentId);
  }

  Appointment? appointmentById(String appointmentId) {
    for (final appointment in _appointments) {
      if (appointment.appointmentId == appointmentId) {
        return appointment;
      }
    }

    return null;
  }

  String? serviceNameFor(String serviceId) => _serviceNames[serviceId];

  String get hospitalName => _hospital?.name ?? 'Assigned hospital';

  List<Appointment> get activeAppointments =>
      _appointments.where(_isActive).toList();

  List<Appointment> get todayAppointments {
    final now = _sriLanka(DateTime.now());

    return _appointments.where((appointment) {
      return _isActive(appointment) &&
          _isSameDay(_sriLanka(appointment.dateTime), now);
    }).toList();
  }

  List<Appointment> get upcomingAppointments {
    final today = _startOfDay(_sriLanka(DateTime.now()));

    return _appointments.where((appointment) {
      return _isActive(appointment) &&
          _startOfDay(_sriLanka(appointment.dateTime)).isAfter(today);
    }).toList();
  }

  int get pendingCount {
    return _appointments.where((appointment) {
      return appointment.status.trim().toLowerCase() == 'pending';
    }).length;
  }

  int get todayCount => todayAppointments.length;

  int get upcomingCount => upcomingAppointments.length;

  Future<void> load() async {
    if (_isDisposed) return;
    final generation = ++_generation;
    _veterinarian = null;
    _hospital = null;
    _appointments = [];
    _serviceNames = {};
    _hospitalWarning = null;
    _processingAppointmentIds.clear();
    _isSavingProfile = false;
    _isUploadingImage = false;
    _isLoading = true;
    _loadErrorMessage = null;
    _actionErrorMessage = null;
    _notify();
    try {
      if (!_current(generation)) throw StateError('session-changed');
      final assignment = await _getAssignment();
      if (!_current(generation)) return;
      if (assignment == null ||
          !assignment.active ||
          assignment.vetId.isEmpty ||
          assignment.hospitalId.isEmpty) {
        throw StateError('assignment-unverified');
      }
      final appointments = await _getAppointments(
        vetId: assignment.vetId,
        hospitalId: assignment.hospitalId,
      );
      if (!_current(generation)) return;
      if (appointments.any(
        (a) =>
            a.vetId != assignment.vetId ||
            a.hospitalId != assignment.hospitalId,
      )) {
        throw StateError('appointment-assignment-mismatch');
      }
      final hospital = await _safeHospital(assignment.hospitalId);
      if (!_current(generation)) return;
      if (hospital != null &&
          (!hospital.active || hospital.hospitalId != assignment.hospitalId)) {
        throw StateError('hospital-assignment-invalid');
      }
      final services = await _safeServices(assignment.hospitalId);
      if (!_current(generation)) return;
      _appointments = List<Appointment>.of(appointments)
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _veterinarian = assignment;
      _hospital = hospital;
      _serviceNames = {
        for (final service in services) service.serviceId: service.name,
      };
    } catch (error) {
      if (_isDisposed || generation != _generation) return;
      debugPrint(
        'V01 workspace load code=${error is FirebaseException ? error.code : error.runtimeType}',
      );
      _loadErrorMessage = _message(error);
    } finally {
      if (!_isDisposed && generation == _generation) {
        _isLoading = false;
        _notify();
      }
    }
  }

  String _message(Object error) {
    if (error is StateError) {
      return 'Your veterinarian assignment could not be verified. Contact your hospital.';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return 'Dashboard access could not be authorized. Contact your hospital.';
        case 'failed-precondition':
          return 'The dashboard service needs configuration. Contact support.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Unable to connect. Please check your connection and try again.';
      }
    }
    return 'Unable to load veterinarian information. Please check your connection and try again.';
  }

  Future<void> refresh() => load();

  Future<bool> confirmAppointment(String appointmentId) {
    return _decideAppointment(
      appointmentId: appointmentId,
      nextStatus: 'confirmed',
      action: _confirmAppointment.call,
    );
  }

  Future<bool> rejectAppointment(String appointmentId) {
    return _decideAppointment(
      appointmentId: appointmentId,
      nextStatus: 'rejected',
      action: _rejectAppointment.call,
    );
  }

  Future<bool> _decideAppointment({
    required String appointmentId,
    required String nextStatus,
    required Future<void> Function(String) action,
  }) async {
    if (_isDisposed || _processingAppointmentIds.contains(appointmentId)) {
      return false;
    }

    final generation = _generation;
    if (!_current(generation) || _veterinarian == null) return false;
    final appointment = appointmentById(appointmentId);

    if (appointment == null ||
        appointment.status.trim().toLowerCase() != 'pending') {
      _actionErrorMessage = 'Only pending appointments can be updated.';
      _notify();
      return false;
    }

    _processingAppointmentIds.add(appointmentId);
    _actionErrorMessage = null;
    _notify();

    try {
      await action(appointmentId);

      if (!_current(generation)) return false;

      _replaceAppointment(appointmentId, _withStatus(appointment, nextStatus));
      return true;
    } catch (error) {
      debugPrint(
        'Veterinarian appointment update failed: ${error.runtimeType}',
      );

      if (_current(generation)) {
        _actionErrorMessage =
            'Unable to update the appointment. Please try again.';
      }

      return false;
    } finally {
      if (_current(generation)) {
        _processingAppointmentIds.remove(appointmentId);
        _notify();
      }
    }
  }

  Future<String?> uploadProfileImage(Uint8List bytes) async {
    final generation = _generation;
    if (!_current(generation)) return null;
    final vetId = _veterinarian?.vetId;

    if (vetId == null || vetId.isEmpty) {
      _profileErrorMessage = 'Your veterinarian profile is unavailable.';
      _notify();
      return null;
    }

    if (_isUploadingImage) return null;

    _isUploadingImage = true;
    _profileErrorMessage = null;
    _notify();

    try {
      final result = await _imageRepository.uploadVeterinarianImage(
        vetId: vetId,
        bytes: bytes,
      );
      return _current(generation) ? result : null;
    } catch (error) {
      debugPrint('Veterinarian image upload failed: ${error.runtimeType}');

      if (_current(generation)) {
        _profileErrorMessage = error is VeterinarianImageRepositoryException
            ? error.message
            : 'Unable to upload the profile image. Please try again.';
      }

      return null;
    } finally {
      if (_current(generation)) {
        _isUploadingImage = false;
        _notify();
      }
    }
  }

  Future<bool> updateProfessionalProfile({
    required String name,
    required String? profileImageUrl,
    String? specialty,
    String? qualifications,
    int? experienceYears,
    String? bio,
  }) async {
    final generation = _generation;
    if (!_current(generation)) return false;
    final current = _veterinarian;

    if (_isDisposed || current == null || _isSavingProfile) {
      return false;
    }

    _isSavingProfile = true;
    _profileErrorMessage = null;
    _notify();

    try {
      await _updateVeterinarianProfile(
        vetId: current.vetId,
        name: name,
        profileImageUrl: profileImageUrl,
        specialty: specialty,
        qualifications: qualifications,
        experienceYears: experienceYears,
        bio: bio,
      );

      if (!_current(generation)) return false;

      _veterinarian = Veterinarian(
        vetId: current.vetId,
        hospitalId: current.hospitalId,
        name: name.trim(),
        profileImageUrl: _normalize(profileImageUrl),
        specialty: _normalize(specialty),
        qualifications: _normalize(qualifications),
        experienceYears: experienceYears,
        bio: _normalize(bio),
        active: current.active,
      );

      return true;
    } catch (error) {
      debugPrint('Veterinarian profile update failed: ${error.runtimeType}');

      if (_current(generation)) {
        _profileErrorMessage = error is VeterinarianProfileValidationException
            ? error.message
            : 'Unable to update your profile. Please try again.';
      }

      return false;
    } finally {
      if (_current(generation)) {
        _isSavingProfile = false;
        _notify();
      }
    }
  }

  Future<Hospital?> _safeHospital(String hospitalId) async {
    try {
      final hospital = await _getHospital(hospitalId);
      if (hospital == null) {
        _hospitalWarning =
            'Hospital details are unavailable. Contact your hospital.';
      }
      return hospital;
    } catch (error) {
      if (error is FirebaseException &&
          {'permission-denied', 'unauthenticated'}.contains(error.code)) {
        rethrow;
      }
      _hospitalWarning =
          'Hospital details could not be loaded. Pull down to retry.';
      debugPrint('Veterinarian hospital loading failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<List<Service>> _safeServices(String hospitalId) async {
    try {
      return await _getServices(hospitalId);
    } catch (error) {
      if (error is FirebaseException &&
          {'permission-denied', 'unauthenticated'}.contains(error.code)) {
        rethrow;
      }
      debugPrint('Veterinarian services loading failed: ${error.runtimeType}');
      return const [];
    }
  }

  void _replaceAppointment(String appointmentId, Appointment replacement) {
    final index = _appointments.indexWhere(
      (appointment) => appointment.appointmentId == appointmentId,
    );

    if (index == -1) return;

    _appointments = List<Appointment>.of(_appointments)..[index] = replacement;
  }

  Appointment _withStatus(Appointment appointment, String status) {
    return Appointment(
      appointmentId: appointment.appointmentId,
      ownerId: appointment.ownerId,
      petId: appointment.petId,
      hospitalId: appointment.hospitalId,
      serviceId: appointment.serviceId,
      vetId: appointment.vetId,
      dateTime: appointment.dateTime,
      reason: appointment.reason,
      status: status,
      queueId: appointment.queueId,
      createdAt: appointment.createdAt,
    );
  }

  bool _isActive(Appointment appointment) {
    final status = appointment.status.trim().toLowerCase();
    return status == 'pending' || status == 'confirmed';
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _generation++;
    _authSubscription?.cancel();
    _isDisposed = true;
    super.dispose();
  }
}
