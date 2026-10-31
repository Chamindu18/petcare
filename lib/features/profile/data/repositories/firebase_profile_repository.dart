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
    final user = _auth.currentUser;

    if (user == null) {
      throw const ProfileRepositoryException(
        'You must be signed in to update your profile.',
      );
    }

    final normalizedFullName = fullName.trim();
    final normalizedPhone = phone.trim();

    if (normalizedFullName.isEmpty) {
      throw const ProfileRepositoryException('Full name cannot be empty.');
    }

    final previousDisplayName = user.displayName;

    // Update Auth first because the home dashboard reads this display name.
    try {
      await user.updateDisplayName(normalizedFullName);
    } catch (_) {
      throw const ProfileRepositoryException(
        'Unable to update your account name. Please try again.',
      );
    }

    try {
      await _usersCollection.doc(user.uid).update({
        'fullName': normalizedFullName,
        'displayName': normalizedFullName,
        'phone': normalizedPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Firestore failed after Auth was updated.
      // Attempt to restore the previous Auth display name.
      try {
        await user.updateDisplayName(previousDisplayName);
      } catch (_) {
        throw const ProfileRepositoryException(
          'Your account name changed, but your profile could not be saved '
          'and the previous name could not be restored. Please contact '
          'support before retrying.',
        );
      }

      rethrow;
    }
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
