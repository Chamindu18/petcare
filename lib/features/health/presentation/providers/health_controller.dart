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
    required CreateMedicalCondition createMedicalCondition,
    required GetMedicalConditions getMedicalConditions,
    required UpdateMedicalCondition updateMedicalCondition,
    required DeleteMedicalCondition deleteMedicalCondition,
    required CreateVaccination createVaccination,
    required GetVaccinations getVaccinations,
    required UpdateVaccination updateVaccination,
    required DeleteVaccination deleteVaccination,
    required CreateTreatment createTreatment,
    required GetTreatments getTreatments,
    required UpdateTreatment updateTreatment,
    required DeleteTreatment deleteTreatment,
    required CreateHealthMeasurement createHealthMeasurement,
    required GetHealthMeasurements getHealthMeasurements,
    required UpdateHealthMeasurement updateHealthMeasurement,
    required DeleteHealthMeasurement deleteHealthMeasurement,
  }) : _createMedicalCondition = createMedicalCondition,
       _getMedicalConditions = getMedicalConditions,
       _updateMedicalCondition = updateMedicalCondition,
       _deleteMedicalCondition = deleteMedicalCondition,
       _createVaccination = createVaccination,
       _getVaccinations = getVaccinations,
       _updateVaccination = updateVaccination,
       _deleteVaccination = deleteVaccination,
       _createTreatment = createTreatment,
       _getTreatments = getTreatments,
       _updateTreatment = updateTreatment,
       _deleteTreatment = deleteTreatment,
       _createHealthMeasurement = createHealthMeasurement,
       _getHealthMeasurements = getHealthMeasurements,
       _updateHealthMeasurement = updateHealthMeasurement,
       _deleteHealthMeasurement = deleteHealthMeasurement;

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

  Future<void> createMedicalCondition(MedicalCondition condition) async {
    await _run(() async {
      final createdCondition = await _createMedicalCondition(condition);

      _medicalConditions = [..._medicalConditions, createdCondition];
    });
  }

  Future<void> updateMedicalCondition(MedicalCondition condition) async {
    await _run(() async {
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

  Future<void> deleteMedicalCondition(String petId, String conditionId) async {
    await _run(() async {
      await _deleteMedicalCondition(petId, conditionId);

      _medicalConditions = _medicalConditions
          .where((item) => item.conditionId != conditionId)
          .toList();
    });
  }

  Future<void> createVaccination(Vaccination vaccination) async {
    await _run(() async {
      final createdVaccination = await _createVaccination(vaccination);

      _vaccinations = [..._vaccinations, createdVaccination];
    });
  }

  Future<void> updateVaccination(Vaccination vaccination) async {
    await _run(() async {
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

  Future<void> deleteVaccination(String petId, String vaccinationId) async {
    await _run(() async {
      await _deleteVaccination(petId, vaccinationId);

      _vaccinations = _vaccinations
          .where((item) => item.vaccinationId != vaccinationId)
          .toList();
    });
  }

  Future<void> createTreatment(Treatment treatment) async {
    await _run(() async {
      final createdTreatment = await _createTreatment(treatment);

      _treatments = [..._treatments, createdTreatment];
    });
  }

  Future<void> updateTreatment(Treatment treatment) async {
    await _run(() async {
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

  Future<void> deleteTreatment(String petId, String treatmentId) async {
    await _run(() async {
      await _deleteTreatment(petId, treatmentId);

      _treatments = _treatments
          .where((item) => item.treatmentId != treatmentId)
          .toList();
    });
  }

  Future<void> createHealthMeasurement(HealthMeasurement measurement) async {
    await _run(() async {
      final createdMeasurement = await _createHealthMeasurement(measurement);

      _healthMeasurements = [..._healthMeasurements, createdMeasurement];
    });
  }

  Future<void> updateHealthMeasurement(HealthMeasurement measurement) async {
    await _run(() async {
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

  Future<void> deleteHealthMeasurement(
    String petId,
    String measurementId,
  ) async {
    await _run(() async {
      await _deleteHealthMeasurement(petId, measurementId);

      _healthMeasurements = _healthMeasurements
          .where((item) => item.measurementId != measurementId)
          .toList();
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await operation();
    } catch (_) {
      _errorMessage = 'Unable to complete the health operation.';
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
}
