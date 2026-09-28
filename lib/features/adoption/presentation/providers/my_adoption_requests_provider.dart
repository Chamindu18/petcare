import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/adoption_request.dart';
import '../../domain/repositories/adoption_request_repository.dart';

class MyAdoptionRequestsProvider extends ChangeNotifier {
  MyAdoptionRequestsProvider({required this._repository});

  final AdoptionRequestRepository _repository;

  StreamSubscription<List<AdoptionRequest>>? _subscription;

  List<AdoptionRequest> _requests = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<AdoptionRequest> get requests => List.unmodifiable(_requests);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasNoRequests =>
      !_isLoading && _errorMessage == null && _requests.isEmpty;

  void startListening() {
    _subscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _repository.watchMyRequests().listen(
      (requests) {
        _requests = requests;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = _errorMessageFrom(error);
        notifyListeners();
      },
    );
  }

  String _errorMessageFrom(Object error) {
    return 'Unable to load your adoption requests. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
