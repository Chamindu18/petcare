import 'package:flutter/foundation.dart';

import '../../../services/domain/entities/service.dart';
import '../../../services/domain/usecases/service_usecases.dart';
import '../../../veterinary/domain/entities/veterinarian.dart';
import '../../../veterinary/domain/usecases/veterinarian_usecases.dart';
import '../../domain/entities/hospital.dart';
import '../../domain/usecases/hospital_usecases.dart';

/// Loads all information required by the hospital details screen.
class HospitalDetailsProvider extends ChangeNotifier {
  HospitalDetailsProvider({
    required this._getHospitalById,
    required this._getServicesByHospital,
    required this._getVeterinariansByHospital,
  });

  final GetHospitalById _getHospitalById;
  final GetServicesByHospital _getServicesByHospital;
  final GetVeterinariansByHospital _getVeterinariansByHospital;

  Hospital? _hospital;
  List<Service> _services = [];
  List<Veterinarian> _veterinarians = [];

  bool _isLoading = false;
  String? _errorMessage;

  Hospital? get hospital => _hospital;

  List<Service> get services => List.unmodifiable(_services);

  List<Veterinarian> get veterinarians => List.unmodifiable(_veterinarians);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Loads the hospital and its related services and veterinarians.
  Future<void> loadHospital(String hospitalId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load the hospital itself.
      _hospital = await _getHospitalById(hospitalId);

      // Load services and veterinarians for this hospital.
      final results = await Future.wait([
        _getServicesByHospital(hospitalId),
        _getVeterinariansByHospital(hospitalId),
      ]);

      _services = results[0] as List<Service>;
      _veterinarians = results[1] as List<Veterinarian>;

      if (_hospital == null) {
        _errorMessage = 'Hospital not found.';
      }
    } catch (error, stackTrace) {
  debugPrint('HOSPITAL DETAILS ERROR: $error');
  debugPrintStack(stackTrace: stackTrace);
  _errorMessage = 'Unable to load hospital details. Please try again.';
} finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
