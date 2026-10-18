import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/shared/enums/user_role.dart';

void main() {
  group('UserRoleX Firestore mapping', () {
    const expectedRoles = <String, UserRole>{
      'owner': UserRole.owner,
      'veterinarian': UserRole.veterinarian,
      'veterinary_staff': UserRole.veterinaryStaff,
      'adoption_provider': UserRole.adoptionProvider,
    };

    for (final entry in expectedRoles.entries) {
      test('parses ${entry.key}', () {
        expect(UserRoleX.tryParseFirestore(entry.key), entry.value);

        expect(entry.value.firestoreValue, entry.key);
      });
    }

    test('returns null for missing or unknown roles', () {
      expect(UserRoleX.tryParseFirestore(null), isNull);
      expect(UserRoleX.tryParseFirestore(''), isNull);
      expect(UserRoleX.tryParseFirestore('admin'), isNull);
      expect(UserRoleX.tryParseFirestore('unknown_role'), isNull);
    });

    test('fromFirestore still throws for unknown roles', () {
      expect(
        () => UserRoleX.fromFirestore('unknown_role'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
