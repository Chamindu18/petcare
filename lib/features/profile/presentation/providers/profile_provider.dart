import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required this._repository});
  final ProfileRepository _repository;

  StreamSubscription<UserProfile?>? _subscription;

  UserProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startListening() {
    _subscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _repository.watchCurrentProfile().listen(
      (profile) {
        _profile = profile;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'Unable to load your profile. Please try again.';
        notifyListeners();
      },
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    try {
      await _repository.updateProfile(fullName: fullName, phone: phone);
    } catch (error) {
      _errorMessage = 'Unable to update your profile. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateNotificationPreference({required bool enabled}) async {
    try {
      await _repository.updateNotificationPreference(enabled: enabled);
    } catch (error) {
      _errorMessage =
          'Unable to update notification settings. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
