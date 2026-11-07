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

  List<MedicalCondition> get medicalConditions =>
      List.unmodifiable(_medicalConditions);

  List<Vaccination> get vaccinations => List.unmodifiable(_vaccinations);

  List<Treatment> get treatments => List.unmodifiable(_treatments);

  List<HealthMeasurement> get healthMeasurements =>
      List.unmodifiable(_healthMeasurements);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Load health records
  // ---------------------------------------------------------------------------

  Future<void> loadHealthRecords(String petId) async {
    await _run(() async {
      final results = await Future.wait([
        _getMedicalConditions(petId),
        _getVaccinations(petId),
        _getTreatments(petId),
        _getHealthMeasurements(petId),
      ]);

      _medicalConditions = results[0] as List<MedicalCondition>;
      _vaccinations = results[1] as List<Vaccination>;
      _treatments = results[2] as List<Treatment>;
      _healthMeasurements = results[3] as List<HealthMeasurement>;
    });
  }

  // ---------------------------------------------------------------------------
  // Medical conditions
  // ---------------------------------------------------------------------------

  Future<bool> createMedicalCondition(MedicalCondition condition) async {
    return _run(() async {
      final createdCondition = await _createMedicalCondition(condition);

      _medicalConditions = [..._medicalConditions, createdCondition];
    });
  }

  Future<bool> updateMedicalCondition(MedicalCondition condition) async {
    return _run(() async {
      await _updateMedicalCondition(condition);

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
    return _run(() async {
      await _deleteMedicalCondition(petId, conditionId);

      _medicalConditions = _medicalConditions
          .where((item) => item.conditionId != conditionId)
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Vaccinations
  // ---------------------------------------------------------------------------

  Future<bool> createVaccination(Vaccination vaccination) async {
    return _run(() async {
      final createdVaccination = await _createVaccination(vaccination);

      _vaccinations = [..._vaccinations, createdVaccination];
    });
  }

  Future<bool> updateVaccination(Vaccination vaccination) async {
    return _run(() async {
      await _updateVaccination(vaccination);

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
    return _run(() async {
      await _deleteVaccination(petId, vaccinationId);

      _vaccinations = _vaccinations
          .where((item) => item.vaccinationId != vaccinationId)
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Treatments
  // ---------------------------------------------------------------------------

  Future<bool> createTreatment(Treatment treatment) async {
    return _run(() async {
      final createdTreatment = await _createTreatment(treatment);

      _treatments = [..._treatments, createdTreatment];
    });
  }

  Future<bool> updateTreatment(Treatment treatment) async {
    return _run(() async {
      await _updateTreatment(treatment);

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
    return _run(() async {
      await _deleteTreatment(petId, treatmentId);

      _treatments = _treatments
          .where((item) => item.treatmentId != treatmentId)
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Health measurements
  // ---------------------------------------------------------------------------

  Future<bool> createHealthMeasurement(HealthMeasurement measurement) async {
    return _run(() async {
      final createdMeasurement = await _createHealthMeasurement(measurement);

      _healthMeasurements = [..._healthMeasurements, createdMeasurement];
    });
  }

  Future<bool> updateHealthMeasurement(HealthMeasurement measurement) async {
    return _run(() async {
      await _updateHealthMeasurement(measurement);

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
    return _run(() async {
      await _deleteHealthMeasurement(petId, measurementId);

      _healthMeasurements = _healthMeasurements
          .where((item) => item.measurementId != measurementId)
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Operation handling
  // ---------------------------------------------------------------------------

  Future<bool> _run(Future<void> Function() operation) async {
    // Do not start a second operation while another is running.
    // Return false so the caller cannot incorrectly report success.
    if (_isLoading) {
      return false;
    }

    // Clear the previous error before notifying listeners that work has begun.
    _errorMessage = null;
    _setLoading(true);

    try {
      await operation();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to complete the health operation.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool get hasData =>
      _medicalConditions.isNotEmpty ||
      _vaccinations.isNotEmpty ||
      _treatments.isNotEmpty ||
      _healthMeasurements.isNotEmpty;
}
