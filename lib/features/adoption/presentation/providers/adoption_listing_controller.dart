import 'package:flutter/foundation.dart';

import '../../domain/entities/adoption_listing.dart';
import '../../domain/usecases/create_adoption_listing.dart';
import '../../domain/usecases/update_adoption_listing.dart';

class AdoptionListingController extends ChangeNotifier {
  AdoptionListingController(
    this._createAdoptionListing,
    this._updateAdoptionListing,
  );

  final CreateAdoptionListing _createAdoptionListing;
  final UpdateAdoptionListing _updateAdoptionListing;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<AdoptionListing?> create(AdoptionListing listing) async {
    AdoptionListing? createdListing;

    await _run(() async {
      createdListing = await _createAdoptionListing(listing);
    });

    return createdListing;
  }

  Future<bool> update(AdoptionListing listing) async {
    var updated = false;

    await _run(() async {
      await _updateAdoptionListing(listing);
      updated = true;
    });

    return updated;
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await operation();
    } catch (_) {
      _errorMessage = 'Unable to save the adoption listing.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
