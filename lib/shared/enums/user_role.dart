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

  static UserRole fromFirestore(String value) {
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
        throw ArgumentError('Unknown user role: $value');
    }
  }
}
