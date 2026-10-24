import 'package:flutter/foundation.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/usecases/appointment_usecases.dart';

/// Holds the appointment list state used by the owner UI.
class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider({
    required this._getAppointments,
  });

  final GetAppointments _getAppointments;

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Appointments currently loaded for the signed-in owner.
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Loads appointments belonging to the current signed-in user.
  Future<void> loadAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // The repository gets the current owner from Firebase Auth.
      _appointments = await _getAppointments();
    } catch (error) {
      // Keep the technical error out of the UI.
      debugPrint('Appointment loading error: $error');
      _errorMessage = 'Unable to load appointments. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}