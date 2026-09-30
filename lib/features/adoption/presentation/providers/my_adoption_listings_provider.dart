import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/adoption_listing.dart';
import '../../domain/repositories/adoption_listing_repository.dart';

class MyAdoptionListingsProvider extends ChangeNotifier {
  MyAdoptionListingsProvider({required this.repository});

  final AdoptionListingRepository repository;
  StreamSubscription<List<AdoptionListing>>? _subscription;

  List<AdoptionListing> _listings = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<AdoptionListing> get listings => List.unmodifiable(_listings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasNoListings =>
      !_isLoading && _errorMessage == null && _listings.isEmpty;

  void startListening() {
    _subscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = repository.watchMyListings().listen(
      (listings) {
        _listings = listings;
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
    return 'Unable to load your adoption listings. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
