class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.role,
    required this.notificationEnabled,
  });

  final String uid;
  final String fullName;
  final String displayName;
  final String email;
  final String phone;
  final String role;
  final bool notificationEnabled;
}
