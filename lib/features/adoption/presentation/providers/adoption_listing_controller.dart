import 'package:flutter/foundation.dart';

import '../../domain/entities/adoption_listing.dart';
import '../../domain/usecases/create_adoption_listing.dart';
import '../../domain/usecases/update_adoption_listing.dart';
import '../../domain/usecases/upload_adoption_image.dart';

class AdoptionListingController extends ChangeNotifier {
  AdoptionListingController(
    this._createAdoptionListing,
    this._updateAdoptionListing,
    this._uploadAdoptionImage,
  );

  final CreateAdoptionListing _createAdoptionListing;
  final UpdateAdoptionListing _updateAdoptionListing;
  final UploadAdoptionImage _uploadAdoptionImage;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Creates the adoption listing first so the generated listing ID
  /// can be used for the Cloudinary image path.
  Future<AdoptionListing?> create(
    AdoptionListing listing, {
    Uint8List? imageBytes,
  }) async {
    AdoptionListing? createdListing;

    await _run(() async {
      createdListing = await _createAdoptionListing(listing);

      if (createdListing == null || imageBytes == null || imageBytes.isEmpty) {
        return;
      }

      final imageUrl = await _uploadAdoptionImage(
        listingId: createdListing!.listingId,
        bytes: imageBytes,
      );

      final listingWithImage = createdListing!.copyWith(imageAsset: imageUrl);

      await _updateAdoptionListing(listingWithImage);

      createdListing = listingWithImage;
    });

    return createdListing;
  }

  /// Updates an existing adoption listing.
  ///
  /// If a new image is supplied, it is uploaded to Cloudinary first and
  /// the resulting URL is persisted with the listing.
  Future<bool> update(AdoptionListing listing, {Uint8List? imageBytes}) async {
    var updated = false;

    await _run(() async {
      var listingToUpdate = listing;

      if (imageBytes != null && imageBytes.isNotEmpty) {
        final imageUrl = await _uploadAdoptionImage(
          listingId: listing.listingId,
          bytes: imageBytes,
        );

        listingToUpdate = listing.copyWith(imageAsset: imageUrl);
      }

      await _updateAdoptionListing(listingToUpdate);
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
