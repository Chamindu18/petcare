import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_profile_model.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw const ProfileRepositoryException(
        'You must be signed in to access your profile.',
      );
    }

    return user.uid;
  }

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    final userId = _currentUserId;

    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return UserProfileModel.fromMap(snapshot.data()!);
    });
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final userId = _currentUserId;

    final normalizedFullName = fullName.trim();
    final normalizedPhone = phone.trim();

    if (normalizedFullName.isEmpty) {
      throw const ProfileRepositoryException('Full name cannot be empty.');
    }

    await _usersCollection.doc(userId).update({
      'fullName': normalizedFullName,
      'displayName': normalizedFullName,
      'phone': normalizedPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auth.currentUser?.updateDisplayName(normalizedFullName);
  }

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {
    final userId = _currentUserId;

    await _usersCollection.doc(userId).update({
      'notificationEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class ProfileRepositoryException implements Exception {
  const ProfileRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
