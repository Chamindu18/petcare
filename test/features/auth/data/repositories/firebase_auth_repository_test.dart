import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:petcare/features/auth/data/repositories/firebase_auth_repository.dart';

class _FakeFirebaseUser extends Fake implements User {
  @override
  String get uid => 'test-privileged-user';

  @override
  String? get displayName => 'New Test User';

  @override
  String? get email => 'newowner@example.com';

  @override
  String? get phoneNumber => '0712345678';

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> reload() async {}
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

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _userCredential;
  }
}

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {}

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

// Test double for the users collection.
// ignore: subtype_of_sealed_class
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

// Test double for a Firestore document.
// ignore: subtype_of_sealed_class
class _FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this._snapshot);

  final DocumentSnapshot<Map<String, dynamic>> _snapshot;

  final List<Map<Object, Object?>> updates = [];
  final List<Map<String, dynamic>> setCalls = [];

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
    setCalls.add(Map<String, dynamic>.from(data));
  }
}

// Test double for a Firestore document snapshot.
// ignore: subtype_of_sealed_class
class _FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this._profileData, {this._exists = true});

  final Map<String, dynamic> _profileData;
  final bool _exists;

  @override
  bool get exists => _exists;

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

          // Existing role and profile fields must not be overwritten.
          expect(updateFields.keys.toSet(), equals(<String>{'updatedAt'}));

          expect(updateFields.containsKey('role'), isFalse);
          expect(updateFields.containsKey('uid'), isFalse);
          expect(updateFields.containsKey('email'), isFalse);
          expect(updateFields.containsKey('phone'), isFalse);
          expect(updateFields.containsKey('fullName'), isFalse);
          expect(updateFields.containsKey('displayName'), isFalse);

          // Existing profiles must not be replaced.
          expect(fakeUserDocument.setCalls, isEmpty);
        },
      );
    }

    test(
      'creates a new owner profile when no Firestore profile exists',
      () async {
        final fakeUser = _FakeFirebaseUser();
        final fakeUserCredential = _FakeUserCredential(fakeUser);
        final fakeGoogleSignIn = _FakeGoogleSignIn();

        // Simulate a Google-authenticated user without an existing profile.
        final fakeSnapshot = _FakeDocumentSnapshot(
          <String, dynamic>{},
          exists: false,
        );

        final fakeUserDocument = _FakeDocumentReference(fakeSnapshot);

        final fakeUsersCollection = _FakeCollectionReference(fakeUserDocument);

        final repository = FirebaseAuthRepository(
          auth: _FakeFirebaseAuth(fakeUserCredential),
          firestore: _FakeFirebaseFirestore(fakeUsersCollection),
          googleSignIn: fakeGoogleSignIn,
        );

        await repository.signInWithGoogle();

        // A new profile should be created exactly once.
        expect(fakeUserDocument.setCalls, hasLength(1));

        final createdProfile = fakeUserDocument.setCalls.single;

        expect(createdProfile['uid'], 'test-privileged-user');
        expect(createdProfile['fullName'], 'New Test User');
        expect(createdProfile['displayName'], 'New Test User');
        expect(createdProfile['email'], 'newowner@example.com');
        expect(createdProfile['phone'], '0712345678');
        expect(createdProfile['role'], 'owner');
        expect(createdProfile['notificationEnabled'], isTrue);

        // The profile should include both server timestamp fields.
        expect(createdProfile.containsKey('createdAt'), isTrue);
        expect(createdProfile.containsKey('updatedAt'), isTrue);

        // Creating the profile should not use the update-existing path.
        expect(fakeUserDocument.updates, isEmpty);
      },
    );
  });

  group('FirebaseAuthRepository email registration', () {
    test('registerOwner creates a trimmed owner profile', () async {
      final fakeUser = _FakeFirebaseUser();
      final fakeUserCredential = _FakeUserCredential(fakeUser);

      final fakeSnapshot = _FakeDocumentSnapshot(
        <String, dynamic>{},
        exists: false,
      );

      final fakeUserDocument = _FakeDocumentReference(fakeSnapshot);

      final fakeUsersCollection = _FakeCollectionReference(fakeUserDocument);

      final repository = FirebaseAuthRepository(
        auth: _FakeFirebaseAuth(fakeUserCredential),
        firestore: _FakeFirebaseFirestore(fakeUsersCollection),
        googleSignIn: _FakeGoogleSignIn(),
      );

      await repository.registerOwner(
        fullName: '  New Test User ',
        email: ' newowner@example.com ',
        phone: ' 0712345678 ',
        password: 'Password123',
      );

      // Registration must create exactly one profile.
      expect(fakeUserDocument.setCalls, hasLength(1));

      final createdProfile = fakeUserDocument.setCalls.single;

      // Verify the profile identity and normalized user input.
      expect(createdProfile['uid'], 'test-privileged-user');
      expect(createdProfile['fullName'], 'New Test User');
      expect(createdProfile['displayName'], 'New Test User');
      expect(createdProfile['email'], 'newowner@example.com');
      expect(createdProfile['phone'], '0712345678');

      // Public email registration must assign the owner role.
      expect(createdProfile['role'], 'owner');

      // Verify the expected profile defaults and timestamps.
      expect(createdProfile['notificationEnabled'], isTrue);
      expect(createdProfile.containsKey('createdAt'), isTrue);
      expect(createdProfile.containsKey('updatedAt'), isTrue);

      // This is a new profile, so the existing-profile path is not used.
      expect(fakeUserDocument.updates, isEmpty);
    });
  });
}
