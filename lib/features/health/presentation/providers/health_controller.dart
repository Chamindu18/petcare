import 'package:flutter/foundation.dart';

import '../../domain/entities/health_measurement.dart';
import '../../domain/entities/medical_condition.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/vaccination.dart';
import '../../domain/usecases/create_health_measurement.dart';
import '../../domain/usecases/create_medical_condition.dart';
import '../../domain/usecases/create_treatment.dart';
import '../../domain/usecases/create_vaccination.dart';
import '../../domain/usecases/delete_health_measurement.dart';
import '../../domain/usecases/delete_medical_condition.dart';
import '../../domain/usecases/delete_treatment.dart';
import '../../domain/usecases/delete_vaccination.dart';
import '../../domain/usecases/get_health_measurements.dart';
import '../../domain/usecases/get_medical_conditions.dart';
import '../../domain/usecases/get_treatments.dart';
import '../../domain/usecases/get_vaccinations.dart';
import '../../domain/usecases/update_health_measurement.dart';
import '../../domain/usecases/update_medical_condition.dart';
import '../../domain/usecases/update_treatment.dart';
import '../../domain/usecases/update_vaccination.dart';

class HealthController extends ChangeNotifier {
  HealthController({
    required this._createMedicalCondition,
    required this._getMedicalConditions,
    required this._updateMedicalCondition,
    required this._deleteMedicalCondition,
    required this._createVaccination,
    required this._getVaccinations,
    required this._updateVaccination,
    required this._deleteVaccination,
    required this._createTreatment,
    required this._getTreatments,
    required this._updateTreatment,
    required this._deleteTreatment,
    required this._createHealthMeasurement,
    required this._getHealthMeasurements,
    required this._updateHealthMeasurement,
    required this._deleteHealthMeasurement,
  });

  final CreateMedicalCondition _createMedicalCondition;
  final GetMedicalConditions _getMedicalConditions;
  final UpdateMedicalCondition _updateMedicalCondition;
  final DeleteMedicalCondition _deleteMedicalCondition;

  final CreateVaccination _createVaccination;
  final GetVaccinations _getVaccinations;
  final UpdateVaccination _updateVaccination;
  final DeleteVaccination _deleteVaccination;

  final CreateTreatment _createTreatment;
  final GetTreatments _getTreatments;
  final UpdateTreatment _updateTreatment;
  final DeleteTreatment _deleteTreatment;

  final CreateHealthMeasurement _createHealthMeasurement;
  final GetHealthMeasurements _getHealthMeasurements;
  final UpdateHealthMeasurement _updateHealthMeasurement;
  final DeleteHealthMeasurement _deleteHealthMeasurement;

  List<MedicalCondition> _medicalConditions = [];
  List<Vaccination> _vaccinations = [];
  List<Treatment> _treatments = [];
  List<HealthMeasurement> _healthMeasurements = [];

  bool _isLoading = false;
  String? _errorMessage;
  int _loadGeneration = 0;
  bool _loadingHealthRecords = false;
  String? _loadedPetId;
  bool _disposed = false;

  List<MedicalCondition> get medicalConditions =>
      List.unmodifiable(_medicalConditions);

  List<Vaccination> get vaccinations => List.unmodifiable(_vaccinations);

  List<Treatment> get treatments => List.unmodifiable(_treatments);

  List<HealthMeasurement> get healthMeasurements =>
      List.unmodifiable(_healthMeasurements);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;
  String? get loadedPetId => _loadedPetId;

  // ---------------------------------------------------------------------------
  // Load health records
  // ---------------------------------------------------------------------------

  Future<bool> loadHealthRecords(String petId) async {
    if (_disposed || (_isLoading && !_loadingHealthRecords)) return false;

    final generation = ++_loadGeneration;
    _loadingHealthRecords = true;
    _loadedPetId = null;
    _medicalConditions = [];
    _vaccinations = [];
    _treatments = [];
    _healthMeasurements = [];
    _errorMessage = null;
    _setLoading(true);

    try {
      final results = await Future.wait([
        _getMedicalConditions(petId),
        _getVaccinations(petId),
        _getTreatments(petId),
        _getHealthMeasurements(petId),
      ]);

      if (_disposed || generation != _loadGeneration) return false;
      _medicalConditions = results[0] as List<MedicalCondition>;
      _vaccinations = results[1] as List<Vaccination>;
      _treatments = results[2] as List<Treatment>;
      _healthMeasurements = results[3] as List<HealthMeasurement>;
      _loadedPetId = petId;
      return true;
    } catch (_) {
      if (_disposed || generation != _loadGeneration) return false;
      _errorMessage = 'Unable to complete the health operation.';
      return false;
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _loadingHealthRecords = false;
        _setLoading(false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Medical conditions
  // ---------------------------------------------------------------------------

  Future<bool> createMedicalCondition(MedicalCondition condition) async {
    if (!_canCreateForPet(condition.petId)) return false;
    return _run(() async {
      final createdCondition = await _createMedicalCondition(condition);
      if (_disposed) return;
      if (createdCondition.petId != condition.petId ||
          !_canCreateForPet(createdCondition.petId)) {
        throw StateError('Created condition has a different pet.');
      }
      _medicalConditions = [..._medicalConditions, createdCondition];
    });
  }

  Future<bool> updateMedicalCondition(MedicalCondition condition) async {
    if (!_canMutateRecord(
      condition.petId,
      _medicalConditions.any(
        (item) =>
            item.conditionId == condition.conditionId &&
            item.petId == condition.petId,
      ),
    )) {
      return false;
    }
    return _run(() async {
      await _updateMedicalCondition(condition);
      if (_disposed) return;

      final index = _medicalConditions.indexWhere(
        (item) => item.conditionId == condition.conditionId,
      );

      if (index == -1) {
        return;
      }

      final updatedConditions = List<MedicalCondition>.from(_medicalConditions);

      updatedConditions[index] = condition;
      _medicalConditions = updatedConditions;
    });
  }

  Future<bool> deleteMedicalCondition(String petId, String conditionId) async {
    if (!_canMutateRecord(
      petId,
      _medicalConditions.any(
        (item) => item.conditionId == conditionId && item.petId == petId,
      ),
    )) {
      return false;
    }
    return _run(() async {
      await _deleteMedicalCondition(petId, conditionId);
      if (_disposed) return;

      _medicalConditions = _medicalConditions
          .where(
            (item) => item.petId != petId || item.conditionId != conditionId,
          )
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Vaccinations
  // ---------------------------------------------------------------------------

  Future<bool> createVaccination(Vaccination vaccination) async {
    if (!_canCreateForPet(vaccination.petId)) return false;
    return _run(() async {
      final createdVaccination = await _createVaccination(vaccination);
      if (_disposed) return;
      if (createdVaccination.petId != vaccination.petId ||
          !_canCreateForPet(createdVaccination.petId)) {
        throw StateError('Created vaccination has a different pet.');
      }
      _vaccinations = [..._vaccinations, createdVaccination];
    });
  }

  Future<bool> updateVaccination(Vaccination vaccination) async {
    if (!_canMutateRecord(
      vaccination.petId,
      _vaccinations.any(
        (item) =>
            item.vaccinationId == vaccination.vaccinationId &&
            item.petId == vaccination.petId,
      ),
    )) {
      return false;
    }
    return _run(() async {
      await _updateVaccination(vaccination);
      if (_disposed) return;

      final index = _vaccinations.indexWhere(
        (item) => item.vaccinationId == vaccination.vaccinationId,
      );

      if (index == -1) {
        return;
      }

      final updatedVaccinations = List<Vaccination>.from(_vaccinations);

      updatedVaccinations[index] = vaccination;
      _vaccinations = updatedVaccinations;
    });
  }

  Future<bool> deleteVaccination(String petId, String vaccinationId) async {
    if (!_canMutateRecord(
      petId,
      _vaccinations.any(
        (item) => item.vaccinationId == vaccinationId && item.petId == petId,
      ),
    )) {
      return false;
    }
    return _run(() async {
      await _deleteVaccination(petId, vaccinationId);
      if (_disposed) return;

      _vaccinations = _vaccinations
          .where(
            (item) =>
                item.petId != petId || item.vaccinationId != vaccinationId,
          )
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Treatments
  // ---------------------------------------------------------------------------

  Future<bool> createTreatment(Treatment treatment) async {
    if (!_canCreateForPet(treatment.petId)) return false;
    return _run(() async {
      final createdTreatment = await _createTreatment(treatment);
      if (_disposed) return;
      if (createdTreatment.petId != treatment.petId ||
          !_canCreateForPet(createdTreatment.petId)) {
        throw StateError('Created treatment has a different pet.');
      }
      _treatments = [..._treatments, createdTreatment];
    });
  }

  Future<bool> updateTreatment(Treatment treatment) async {
    if (!_canMutateRecord(
      treatment.petId,
      _treatments.any(
        (item) =>
            item.treatmentId == treatment.treatmentId &&
            item.petId == treatment.petId,
      ),
    )) {
      return false;
    }
    return _run(() async {
      await _updateTreatment(treatment);
      if (_disposed) return;

      final index = _treatments.indexWhere(
        (item) => item.treatmentId == treatment.treatmentId,
      );

      if (index == -1) {
        return;
      }

      final updatedTreatments = List<Treatment>.from(_treatments);

      updatedTreatments[index] = treatment;
      _treatments = updatedTreatments;
    });
  }

  Future<bool> deleteTreatment(String petId, String treatmentId) async {
    if (!_canMutateRecord(
      petId,
      _treatments.any(
        (item) => item.treatmentId == treatmentId && item.petId == petId,
      ),
    )) {
      return false;
    }
    return _run(() async {
      await _deleteTreatment(petId, treatmentId);
      if (_disposed) return;

      _treatments = _treatments
          .where(
            (item) => item.petId != petId || item.treatmentId != treatmentId,
          )
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Health measurements
  // ---------------------------------------------------------------------------

  Future<bool> createHealthMeasurement(HealthMeasurement measurement) async {
    if (!_canCreateForPet(measurement.petId)) return false;
    return _run(() async {
      final createdMeasurement = await _createHealthMeasurement(measurement);
      if (_disposed) return;
      if (createdMeasurement.petId != measurement.petId ||
          !_canCreateForPet(createdMeasurement.petId)) {
        throw StateError('Created measurement has a different pet.');
      }
      _healthMeasurements = [..._healthMeasurements, createdMeasurement];
    });
  }

  Future<bool> updateHealthMeasurement(HealthMeasurement measurement) async {
    if (!_canMutateRecord(
      measurement.petId,
      _healthMeasurements.any(
        (item) =>
            item.measurementId == measurement.measurementId &&
            item.petId == measurement.petId,
      ),
    )) {
      return false;
    }
    return _run(() async {
      await _updateHealthMeasurement(measurement);
      if (_disposed) return;

      final index = _healthMeasurements.indexWhere(
        (item) => item.measurementId == measurement.measurementId,
      );

      if (index == -1) {
        return;
      }

      final updatedMeasurements = List<HealthMeasurement>.from(
        _healthMeasurements,
      );

      updatedMeasurements[index] = measurement;
      _healthMeasurements = updatedMeasurements;
    });
  }

  Future<bool> deleteHealthMeasurement(
    String petId,
    String measurementId,
  ) async {
    if (!_canMutateRecord(
      petId,
      _healthMeasurements.any(
        (item) => item.measurementId == measurementId && item.petId == petId,
      ),
    )) {
      return false;
    }
    return _run(() async {
      await _deleteHealthMeasurement(petId, measurementId);
      if (_disposed) return;

      _healthMeasurements = _healthMeasurements
          .where(
            (item) =>
                item.petId != petId || item.measurementId != measurementId,
          )
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Operation handling
  // ---------------------------------------------------------------------------

  Future<bool> _run(Future<void> Function() operation) async {
    // Do not start a second operation while another is running.
    // Return false so the caller cannot incorrectly report success.
    if (_disposed || _isLoading) {
      return false;
    }

    // Clear the previous error before notifying listeners that work has begun.
    _errorMessage = null;
    _setLoading(true);

    try {
      await operation();
      return !_disposed;
    } catch (_) {
      if (_disposed) return false;
      _errorMessage = 'Unable to complete the health operation.';
      return false;
    } finally {
      if (!_disposed) _setLoading(false);
    }
  }

  bool _canCreateForPet(String petId) =>
      !_disposed && (_loadedPetId == null || _loadedPetId == petId);

  bool _canMutateRecord(String petId, bool recordMatches) =>
      !_disposed && _loadedPetId == petId && recordMatches;

  void clearError() {
    if (_disposed || _errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    _isLoading = false;
    _loadingHealthRecords = false;
    super.dispose();
  }

  bool get hasData =>
      _medicalConditions.isNotEmpty ||
      _vaccinations.isNotEmpty ||
      _treatments.isNotEmpty ||
      _healthMeasurements.isNotEmpty;
}
