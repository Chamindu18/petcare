import 'package:flutter/foundation.dart';

import '../../domain/entities/hospital.dart';
import '../../domain/usecases/hospital_usecases.dart';

/// Handles hospital discovery state for the UI.
class HospitalProvider extends ChangeNotifier {
  HospitalProvider({required this._getHospitals});

  final GetHospitals _getHospitals;

  List<Hospital> _hospitals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Hospital> get hospitals => List.unmodifiable(_hospitals);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadHospitals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hospitals = await _getHospitals();
    } catch (error) {
      _errorMessage = 'Unable to load hospitals. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
