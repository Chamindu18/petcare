import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  Stream<UserProfile?> watchCurrentProfile();

  Future<void> updateProfile({required String fullName, required String phone});

  Future<void> updateNotificationPreference({required bool enabled});
}
