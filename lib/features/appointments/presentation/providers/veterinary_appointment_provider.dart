import 'package:flutter/foundation.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/usecases/appointment_usecases.dart';

/// Holds appointment state for veterinary staff and veterinarians.
///
/// Veterinary staff load appointments scoped to their hospital.
/// Veterinarians load appointments scoped to their veterinarian identity
/// and hospital.
class VeterinaryAppointmentProvider extends ChangeNotifier {
  VeterinaryAppointmentProvider({
    required this._getAppointmentsByHospital,
    required this._getAppointmentsByVeterinarian,
  });

  final GetAppointmentsByHospital _getAppointmentsByHospital;
  final GetAppointmentsByVeterinarian _getAppointmentsByVeterinarian;

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Loads all appointments belonging to a hospital.
  ///
  /// Intended for authorized veterinary staff.
  Future<void> loadForHospital(String hospitalId) async {
    await _load(() => _getAppointmentsByHospital(hospitalId));
  }

  /// Loads appointments assigned to a veterinarian within a hospital.
  ///
  /// The hospital scope provides an additional authorization boundary.
  Future<void> loadForVeterinarian({
    required String vetId,
    required String hospitalId,
  }) async {
    await _load(
      () =>
          _getAppointmentsByVeterinarian(vetId: vetId, hospitalId: hospitalId),
    );
  }

  Future<void> _load(Future<List<Appointment>> Function() loader) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _appointments = await loader();
    } catch (error) {
      debugPrint('Veterinary appointment loading error: $error');
      _errorMessage = 'Unable to load appointments. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}
