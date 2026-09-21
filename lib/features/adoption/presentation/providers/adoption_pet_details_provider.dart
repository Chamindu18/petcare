import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/adoption_listing.dart';
import '../../domain/repositories/adoption_listing_repository.dart';

class AdoptionPetDetailsProvider extends ChangeNotifier {
  AdoptionPetDetailsProvider({
    required this._repository,
    required this.listingId,
  });

  final AdoptionListingRepository _repository;
  final String listingId;

  StreamSubscription<AdoptionListing?>? _subscription;

  AdoptionListing? _listing;
  bool _isLoading = true;
  String? _errorMessage;

  AdoptionListing? get listing => _listing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isUnavailable =>
      !_isLoading && _errorMessage == null && _listing == null;

  void startListening() {
    _subscription?.cancel();

    _listing = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _repository
        .watchListing(listingId: listingId)
        .listen(
          (listing) {
            _listing = listing;
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
    return 'Unable to load this adoption listing. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
