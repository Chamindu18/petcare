import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.fullName,
    required super.displayName,
    required super.email,
    required super.phone,
    required super.role,
    required super.notificationEnabled,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? '',
      notificationEnabled: map['notificationEnabled'] as bool? ?? true,
    );
  }

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      uid: profile.uid,
      fullName: profile.fullName,
      displayName: profile.displayName,
      email: profile.email,
      phone: profile.phone,
      role: profile.role,
      notificationEnabled: profile.notificationEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'role': role,
      'notificationEnabled': notificationEnabled,
    };
  }
}
