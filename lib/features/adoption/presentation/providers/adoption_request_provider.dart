import 'package:flutter/foundation.dart';

import '../../domain/repositories/adoption_request_repository.dart';

class AdoptionRequestProvider extends ChangeNotifier {
  AdoptionRequestProvider({required this.repository});

  final AdoptionRequestRepository repository;

  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  bool get isSubmitted => _isSubmitted;
  String? get errorMessage => _errorMessage;

  Future<void> submitRequest({
    required String listingId,
    required String providerId,
    String? recipientId,
    String recipientType = 'adoption_provider',
    String? message,
  }) async {
    if (_isSubmitting) {
      debugPrint('ADOPTION REQUEST: submission already in progress');
      return;
    }

    debugPrint('========== ADOPTION REQUEST START ==========');
    debugPrint('listingId: $listingId');
    debugPrint('providerId: $providerId');
    debugPrint('recipientId: $recipientId');
    debugPrint('recipientType: $recipientType');
    debugPrint('messageLength: ${message?.trim().length ?? 0}');

    _isSubmitting = true;
    _isSubmitted = false;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('ADOPTION REQUEST: calling repository.createRequest()');

      await repository.createRequest(
        listingId: listingId,
        providerId: providerId,
        recipientId: recipientId,
        recipientType: recipientType,
        message: message,
      );

      debugPrint('ADOPTION REQUEST: repository.createRequest() SUCCESS');

      _isSubmitted = true;
    } catch (error, stackTrace) {
      debugPrint('========== ADOPTION REQUEST ERROR ==========');
      debugPrint('ERROR TYPE: ${error.runtimeType}');
      debugPrint('ERROR: $error');
      debugPrint('STACK TRACE:');
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('============================================');

      _errorMessage =
          'Unable to submit your adoption request. Please try again.';
    } finally {
      _isSubmitting = false;
      notifyListeners();

      debugPrint(
        'ADOPTION REQUEST: finished '
        '(isSubmitted=$_isSubmitted, error=$_errorMessage)',
      );
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
