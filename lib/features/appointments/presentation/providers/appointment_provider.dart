import 'package:flutter/foundation.dart';

import '../../../hospitals/domain/entities/hospital.dart';
import '../../../hospitals/domain/repositories/hospital_repository.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/domain/repositories/pet_repository.dart';
import '../../../services/domain/entities/service.dart';
import '../../../services/domain/repositories/service_repository.dart';
import '../../../veterinary/domain/entities/veterinarian.dart';
import '../../../veterinary/domain/repositories/veterinarian_repository.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/appointment_usecases.dart';

/// Holds appointment state and related display data used by the owner UI.
class AppointmentProvider extends ChangeNotifier {
 AppointmentProvider({
  required this._getAppointments,
  required this._petRepository,
  required this._hospitalRepository,
  required this._serviceRepository,
  required this._veterinarianRepository,
});

  final GetAppointments _getAppointments;
  final PetRepository _petRepository;
  final HospitalRepository _hospitalRepository;
  final ServiceRepository _serviceRepository;
  final VeterinarianRepository _veterinarianRepository;

  List<Appointment> _appointments = [];

  final Map<String, Pet> _petsById = {};
  final Map<String, Hospital> _hospitalsById = {};
  final Map<String, Service> _servicesById = {};
  final Map<String, Veterinarian> _veterinariansById = {};

  bool _isLoading = false;
  String? _errorMessage;

  /// Appointments currently loaded for the signed-in owner.
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Returns the pet for an appointment.
  Pet? getPet(String petId) => _petsById[petId];

  /// Returns the hospital for an appointment.
  Hospital? getHospital(String hospitalId) => _hospitalsById[hospitalId];

  /// Returns the service for an appointment.
  Service? getService(String serviceId) => _servicesById[serviceId];

  /// Returns the veterinarian for an appointment.
  Veterinarian? getVeterinarian(String vetId) => _veterinariansById[vetId];

  /// Loads appointments and the related display data.
  Future<void> loadAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // The appointment repository gets the current owner from Firebase Auth.
      _appointments = await _getAppointments();

      await _loadRelatedData();
    } catch (error) {
      // Keep technical errors out of the UI.
      debugPrint('Appointment loading error: $error');
      _errorMessage = 'Unable to load appointments. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resolves related entity IDs for the currently loaded appointments.
  ///
  /// Each unique ID is looked up only once during a refresh.
  Future<void> _loadRelatedData() async {
    _petsById.clear();
    _hospitalsById.clear();
    _servicesById.clear();
    _veterinariansById.clear();

    final petIds = _appointments
        .map((appointment) => appointment.petId)
        .toSet();
    final hospitalIds = _appointments
        .map((appointment) => appointment.hospitalId)
        .toSet();
    final serviceIds = _appointments
        .map((appointment) => appointment.serviceId)
        .toSet();
    final veterinarianIds = _appointments
        .map((appointment) => appointment.vetId)
        .toSet();

    await Future.wait([
      _loadPets(petIds),
      _loadHospitals(hospitalIds),
      _loadServices(serviceIds),
      _loadVeterinarians(veterinarianIds),
    ]);
  }

  Future<void> _loadPets(Set<String> petIds) async {
    final results = await Future.wait(petIds.map(_petRepository.getPetById));

    for (final pet in results) {
      if (pet != null) {
        _petsById[pet.petId] = pet;
      }
    }
  }

  Future<void> _loadHospitals(Set<String> hospitalIds) async {
    final results = await Future.wait(
      hospitalIds.map(_hospitalRepository.getHospitalById),
    );

    for (final hospital in results) {
      if (hospital != null) {
        _hospitalsById[hospital.hospitalId] = hospital;
      }
    }
  }

  Future<void> _loadServices(Set<String> serviceIds) async {
    final results = await Future.wait(
      serviceIds.map(_serviceRepository.getServiceById),
    );

    for (final service in results) {
      if (service != null) {
        _servicesById[service.serviceId] = service;
      }
    }
  }

  Future<void> _loadVeterinarians(Set<String> veterinarianIds) async {
    final results = await Future.wait(
      veterinarianIds.map(_veterinarianRepository.getVeterinarianById),
    );

    for (final veterinarian in results) {
      if (veterinarian != null) {
        _veterinariansById[veterinarian.vetId] = veterinarian;
      }
    }
  }
}
