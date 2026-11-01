import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/profile/data/models/user_profile_model.dart';

void main() {
  group('UserProfileModel', () {
    test('parses veterinary identity fields from Firestore data', () {
      final model = UserProfileModel.fromMap({
        'uid': 'auth_uid_001',
        'fullName': 'Dr. Kasun Perera',
        'displayName': 'Dr. Kasun',
        'email': 'kasun@example.com',
        'phone': '0771234567',
        'role': 'veterinarian',
        'notificationEnabled': true,
        'vetId': 'vet_001',
        'staffId': null,
        'hospitalId': 'hospital_001',
      });

      expect(model.vetId, 'vet_001');
      expect(model.staffId, isNull);
      expect(model.hospitalId, 'hospital_001');
    });

    test('defaults identity fields to null for existing owner data', () {
      final model = UserProfileModel.fromMap({
        'uid': 'owner_uid_001',
        'fullName': 'Test Owner',
        'displayName': 'Test Owner',
        'email': 'owner@example.com',
        'phone': '0711234567',
        'role': 'owner',
        'notificationEnabled': true,
      });

      expect(model.vetId, isNull);
      expect(model.staffId, isNull);
      expect(model.hospitalId, isNull);
    });

    test('preserves identity fields when converting entity to model', () {
      const profile = UserProfileModel(
        uid: 'auth_uid_002',
        fullName: 'Staff Member',
        displayName: 'Staff',
        email: 'staff@example.com',
        phone: '0721234567',
        role: 'veterinary_staff',
        notificationEnabled: true,
        vetId: null,
        staffId: 'staff_001',
        hospitalId: 'hospital_001',
      );

      final model = UserProfileModel.fromEntity(profile);

      expect(model.vetId, isNull);
      expect(model.staffId, 'staff_001');
      expect(model.hospitalId, 'hospital_001');
    });
  });
}
