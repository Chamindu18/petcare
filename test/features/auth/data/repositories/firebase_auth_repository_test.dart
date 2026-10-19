import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:petcare/features/auth/data/repositories/firebase_auth_repository.dart';

class _FakeFirebaseUser extends Fake implements User {
  @override
  String get uid => 'test-privileged-user';
}

class _FakeUserCredential extends Fake implements UserCredential {
  _FakeUserCredential(this._user);

  final User _user;

  @override
  User get user => _user;
}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  _FakeFirebaseAuth(this._userCredential);

  final UserCredential _userCredential;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return _userCredential;
  }
}

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  int initializeCallCount = 0;

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    initializeCallCount++;
  }

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const <String>[],
  }) async {
    return _FakeGoogleSignInAccount();
  }
}

class _FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  @override
  GoogleSignInAuthentication get authentication =>
      const GoogleSignInAuthentication(idToken: 'test-id-token');
}

class _FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  _FakeFirebaseFirestore(this._usersCollection);

  final _FakeCollectionReference _usersCollection;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    if (collectionPath != 'users') {
      throw StateError('Unexpected collection: $collectionPath');
    }

    return _usersCollection;
  }
}

class _FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this._userDocument);

  final _FakeDocumentReference _userDocument;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    if (path != 'test-privileged-user') {
      throw StateError('Unexpected user document: $path');
    }

    return _userDocument;
  }
}

class _FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this._snapshot);

  final DocumentSnapshot<Map<String, dynamic>> _snapshot;

  final List<Map<Object, Object?>> updates = [];
  int setCallCount = 0;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return _snapshot;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updates.add(Map<Object, Object?>.from(data));
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    setCallCount++;
  }
}

class _FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this._profileData);

  final Map<String, dynamic> _profileData;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic>? data() => Map<String, dynamic>.from(_profileData);
}

void main() {
  group('FirebaseAuthRepository Google Sign-In', () {
    const existingPrivilegedRoles = <String>[
      'veterinarian',
      'veterinary_staff',
      'adoption_provider',
    ];

    for (final role in existingPrivilegedRoles) {
      test(
        'updates only the timestamp for an existing $role profile',
        () async {
          final fakeUser = _FakeFirebaseUser();
          final fakeUserCredential = _FakeUserCredential(fakeUser);
          final fakeGoogleSignIn = _FakeGoogleSignIn();

          final fakeSnapshot = _FakeDocumentSnapshot({
            'uid': 'test-privileged-user',
            'role': role,
            'fullName': 'Existing Test User',
            'displayName': 'Existing Test User',
            'email': 'test@example.com',
            'phone': '0712345678',
            'notificationEnabled': true,
          });

          final fakeUserDocument = _FakeDocumentReference(fakeSnapshot);
          final fakeUsersCollection = _FakeCollectionReference(
            fakeUserDocument,
          );

          final repository = FirebaseAuthRepository(
            auth: _FakeFirebaseAuth(fakeUserCredential),
            firestore: _FakeFirebaseFirestore(fakeUsersCollection),
            googleSignIn: fakeGoogleSignIn,
          );

          await repository.signInWithGoogle();

          // Exactly one update should be made to the existing profile.
          expect(fakeUserDocument.updates, hasLength(1));

          final updateFields = fakeUserDocument.updates.single;

          // The existing role and profile fields must not be overwritten.
          expect(updateFields.keys.toSet(), equals(<String>{'updatedAt'}));

          expect(updateFields.containsKey('role'), isFalse);
          expect(updateFields.containsKey('uid'), isFalse);
          expect(updateFields.containsKey('email'), isFalse);
          expect(updateFields.containsKey('phone'), isFalse);
          expect(updateFields.containsKey('fullName'), isFalse);
          expect(updateFields.containsKey('displayName'), isFalse);

          // The existing document must not be replaced by an owner profile.
          expect(fakeUserDocument.setCallCount, 0);
        },
      );
    }
  });
}
