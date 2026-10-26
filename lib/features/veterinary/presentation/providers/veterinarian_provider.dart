import 'package:flutter/foundation.dart';

import '../../../hospitals/domain/entities/hospital.dart';
import '../../../hospitals/domain/repositories/hospital_repository.dart';
import '../../domain/entities/veterinarian.dart';
import '../../domain/usecases/veterinarian_usecases.dart';

class VeterinarianProvider extends ChangeNotifier {
  VeterinarianProvider({
    required this._getVeterinarians,
    required this._hospitalRepository,
  });

  final GetVeterinarians _getVeterinarians;
  final HospitalRepository _hospitalRepository;

  List<Veterinarian> _veterinarians = [];
  final Map<String, Hospital> _hospitalsById = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<Veterinarian> get veterinarians => List.unmodifiable(_veterinarians);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Hospital? getHospital(String hospitalId) {
    return _hospitalsById[hospitalId];
  }

  Future<void> loadVeterinarians() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _veterinarians = await _getVeterinarians();
      await _loadRelatedHospitals();
    } catch (error) {
      debugPrint('Veterinarian loading error: $error');
      _errorMessage = 'Unable to load veterinarians. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRelatedHospitals() async {
    _hospitalsById.clear();

    final hospitalIds = _veterinarians
        .map((veterinarian) => veterinarian.hospitalId)
        .where((hospitalId) => hospitalId.isNotEmpty)
        .toSet();

    final hospitals = await Future.wait(
      hospitalIds.map(_hospitalRepository.getHospitalById),
    );

    for (final hospital in hospitals) {
      if (hospital != null) {
        _hospitalsById[hospital.hospitalId] = hospital;
      }
    }
  }
}
