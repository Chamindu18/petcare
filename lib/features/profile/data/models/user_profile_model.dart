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
    super.vetId,
    super.staffId,
    super.hospitalId,
    super.photoUrl,
  });

  factory UserProfileModel.fromMap(
    Map<String, dynamic> map, {
    String? uid,
    String? photoUrl,
  }) {
    return UserProfileModel(
      uid: uid ?? map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? '',
      notificationEnabled: map['notificationEnabled'] as bool? ?? true,
      vetId: map['vetId'] as String?,
      staffId: map['staffId'] as String?,
      hospitalId: map['hospitalId'] as String?,
      photoUrl: photoUrl,
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
      vetId: profile.vetId,
      staffId: profile.staffId,
      hospitalId: profile.hospitalId,
      photoUrl: profile.photoUrl,
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
      'vetId': vetId,
      'staffId': staffId,
      'hospitalId': hospitalId,
    };
  }
}
