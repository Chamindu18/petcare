import 'package:flutter/foundation.dart';

import '../../domain/repositories/adoption_request_repository.dart';

class AdoptionRequestProvider extends ChangeNotifier {
  AdoptionRequestProvider({required this._repository});

  final AdoptionRequestRepository _repository;

  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  bool get isSubmitted => _isSubmitted;
  String? get errorMessage => _errorMessage;

  Future<void> submitRequest({
    required String listingId,
    required String providerId,
    String? message,
  }) async {
    if (_isSubmitting) {
      return;
    }

    _isSubmitting = true;
    _isSubmitted = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createRequest(
        listingId: listingId,
        providerId: providerId,
        message: message,
      );

      _isSubmitted = true;
    } catch (error) {
      _errorMessage =
          'Unable to submit your adoption request. Please try again.';
    } finally {
      _isSubmitting = false;
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
