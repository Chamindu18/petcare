enum UserRole { owner, veterinarian, veterinaryStaff, adoptionProvider }

extension UserRoleX on UserRole {
  String get firestoreValue {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.veterinarian:
        return 'veterinarian';
      case UserRole.veterinaryStaff:
        return 'veterinary_staff';
      case UserRole.adoptionProvider:
        return 'adoption_provider';
    }
  }

  /// Returns null when the role is missing or unknown.
  /// Callers must not grant access when parsing returns null.
  static UserRole? tryParseFirestore(String? value) {
    switch (value) {
      case 'owner':
        return UserRole.owner;
      case 'veterinarian':
        return UserRole.veterinarian;
      case 'veterinary_staff':
        return UserRole.veterinaryStaff;
      case 'adoption_provider':
        return UserRole.adoptionProvider;
      default:
        return null;
    }
  }

  /// Parses a required role or throws for an unknown value.
  static UserRole fromFirestore(String value) {
    final role = UserRoleX.tryParseFirestore(value);

    if (role == null) {
      throw ArgumentError('Unknown user role: $value');
    }

    return role;
  }
}
