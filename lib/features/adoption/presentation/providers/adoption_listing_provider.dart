import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/adoption_listing.dart';
import '../../domain/repositories/adoption_listing_repository.dart';

class AdoptionListingProvider extends ChangeNotifier {
  AdoptionListingProvider({required this._repository});

  final AdoptionListingRepository _repository;

  StreamSubscription<List<AdoptionListing>>? _subscription;

  List<AdoptionListing> _listings = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  List<AdoptionListing> get listings => _filteredListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  bool get hasNoResults =>
      !_isLoading && _errorMessage == null && listings.isEmpty;

  void startListening() {
    _subscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _repository.watchAvailableListings().listen(
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

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    notifyListeners();
  }

  List<AdoptionListing> get _filteredListings {
    final query = _searchQuery.toLowerCase();

    if (query.isEmpty) {
      return List.unmodifiable(_listings);
    }

    return List.unmodifiable(
      _listings.where((listing) {
        return listing.petName.toLowerCase().contains(query) ||
            listing.species.toLowerCase().contains(query) ||
            (listing.breed?.toLowerCase().contains(query) ?? false) ||
            listing.location.toLowerCase().contains(query);
      }),
    );
  }

  String _errorMessageFrom(Object error) {
    return 'Unable to load adoption listings. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
