import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:petcare/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:petcare/features/auth/domain/repositories/auth_repository.dart';

class _FakeFirebaseUser extends Fake implements User {
  _FakeFirebaseUser({this.name = 'New Test User', this.googleProvider = true});

  final String? name;
  final bool googleProvider;
  @override
  String get uid => 'test-privileged-user';

  @override
  String? get displayName => name;

  @override
  List<UserInfo> get providerData => googleProvider ? [_FakeUserInfo()] : [];

  @override
  String? get email => 'newowner@example.com';

  @override
  String? get phoneNumber => '0712345678';

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> reload() async {}
}

class _FakeUserInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'google.com';
}

class _FakeUserCredential extends Fake implements UserCredential {
  _FakeUserCredential(this._user);

  final User _user;

  @override
  User get user => _user;
}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  _FakeFirebaseAuth(
    this._userCredential, {
    this.failGoogleSignIn = false,
    this.emailSignInErrorCode,
  });

  final UserCredential _userCredential;
  final bool failGoogleSignIn;
  final String? emailSignInErrorCode;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (emailSignInErrorCode case final code?) {
      throw FirebaseAuthException(
        code: code,
        message: 'Sensitive backend detail',
      );
    }
    return _userCredential;
  }

  @override
  User? get currentUser => _userCredential.user;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    if (failGoogleSignIn) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
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
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => transactionHandler(_FakeTransaction(_usersCollection._userDocument));

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
// ignore: subtype_of_sealed_class, must_be_immutable
class _FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this._snapshot);

  DocumentSnapshot<Map<String, dynamic>> _snapshot;

  final List<Map<Object, Object?>> updates = [];
  final List<Map<String, dynamic>> setCalls = [];
  bool failNextSet = false;

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

class _FakeTransaction extends Fake implements Transaction {
  _FakeTransaction(this.document);
  final _FakeDocumentReference document;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async => document._snapshot as DocumentSnapshot<T>;

  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    if (document.failNextSet) {
      document.failNextSet = false;
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    document.setCalls.add(
      Map<String, dynamic>.from(data as Map<String, dynamic>),
    );
    document._snapshot = _FakeDocumentSnapshot(document.setCalls.last);
    return this;
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
  group('FirebaseAuthRepository email login', () {
    const credentialMessage = 'Invalid email or password. Please try again.';

    FirebaseAuthRepository repositoryFor({String? errorCode}) {
      return FirebaseAuthRepository(
        auth: _FakeFirebaseAuth(
          _FakeUserCredential(_FakeFirebaseUser()),
          emailSignInErrorCode: errorCode,
        ),
        firestore: _FakeFirebaseFirestore(
          _FakeCollectionReference(
            _FakeDocumentReference(_FakeDocumentSnapshot({}, exists: false)),
          ),
        ),
        googleSignIn: _FakeGoogleSignIn(),
      );
    }

    for (final code in [
      'user-not-found',
      'wrong-password',
      'invalid-credential',
      'user-disabled',
    ]) {
      test('$code uses the same safe credential error', () async {
        final repository = repositoryFor(errorCode: code);

        await expectLater(
          repository.signInWithEmailPassword(
            email: 'owner@example.com',
            password: 'incorrect-password',
          ),
          throwsA(
            isA<AuthException>().having(
              (error) => error.message,
              'message',
              credentialMessage,
            ),
          ),
        );
      });
    }

    for (final entry in {
      'network-request-failed':
          'Network error. Check your connection and try again.',
      'too-many-requests': 'Too many attempts. Please try again later.',
      'unavailable':
          'The service is temporarily unavailable. Please try again later.',
    }.entries) {
      test('${entry.key} retains an operational error', () async {
        await expectLater(
          repositoryFor(errorCode: entry.key).signInWithEmailPassword(
            email: 'owner@example.com',
            password: 'valid-password',
          ),
          throwsA(
            isA<AuthException>().having(
              (error) => error.message,
              'message',
              entry.value,
            ),
          ),
        );
      });
    }

    test('successful email sign-in completes', () async {
      await repositoryFor().signInWithEmailPassword(
        email: 'owner@example.com',
        password: 'valid-password',
      );
    });
  });

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

    test(
      'missing Google name waits for user input before creating a profile',
      () async {
        final document = _FakeDocumentReference(
          _FakeDocumentSnapshot({}, exists: false),
        );
        final repository = FirebaseAuthRepository(
          auth: _FakeFirebaseAuth(
            _FakeUserCredential(_FakeFirebaseUser(name: null)),
          ),
          firestore: _FakeFirebaseFirestore(_FakeCollectionReference(document)),
          googleSignIn: _FakeGoogleSignIn(),
        );

        await repository.signInWithGoogle();
        expect(document.setCalls, isEmpty);
        await expectLater(
          repository.completeGoogleOwnerProfile('  '),
          throwsA(isA<AuthException>()),
        );
        expect(document.setCalls, isEmpty);

        await repository.completeGoogleOwnerProfile('  Actual Owner  ');
        expect(document.setCalls, hasLength(1));
        expect(document.setCalls.single['fullName'], 'Actual Owner');
        expect(document.setCalls.single['displayName'], 'Actual Owner');
        expect(document.setCalls.single['role'], 'owner');
      },
    );

    test(
      'failed profile creation can be retried without overwriting a role',
      () async {
        final document = _FakeDocumentReference(
          _FakeDocumentSnapshot({}, exists: false),
        )..failNextSet = true;
        final repository = FirebaseAuthRepository(
          auth: _FakeFirebaseAuth(
            _FakeUserCredential(_FakeFirebaseUser(name: null)),
          ),
          firestore: _FakeFirebaseFirestore(_FakeCollectionReference(document)),
          googleSignIn: _FakeGoogleSignIn(),
        );

        await expectLater(
          repository.completeGoogleOwnerProfile('Actual Owner'),
          throwsA(isA<AuthException>()),
        );
        expect(document.setCalls, isEmpty);

        await repository.completeGoogleOwnerProfile('Actual Owner');
        expect(document.setCalls, hasLength(1));
        expect(document.setCalls.single['role'], 'owner');

        await repository.completeGoogleOwnerProfile('Different Name');
        expect(document.setCalls, hasLength(1));
        expect(document.setCalls.single['fullName'], 'Actual Owner');
      },
    );

    test('completion never replaces an existing privileged profile', () async {
      final document = _FakeDocumentReference(
        _FakeDocumentSnapshot({
          'uid': 'test-privileged-user',
          'role': 'veterinarian',
          'fullName': 'Existing Vet',
        }),
      );
      final repository = FirebaseAuthRepository(
        auth: _FakeFirebaseAuth(
          _FakeUserCredential(_FakeFirebaseUser(name: null)),
        ),
        firestore: _FakeFirebaseFirestore(_FakeCollectionReference(document)),
        googleSignIn: _FakeGoogleSignIn(),
      );

      await repository.completeGoogleOwnerProfile('Other Name');
      expect(document.setCalls, isEmpty);
      expect(document.updates, isEmpty);
      expect(document._snapshot.data()!['role'], 'veterinarian');
    });

    test('non-Google account cannot use Google profile completion', () async {
      final document = _FakeDocumentReference(
        _FakeDocumentSnapshot({}, exists: false),
      );
      final repository = FirebaseAuthRepository(
        auth: _FakeFirebaseAuth(
          _FakeUserCredential(
            _FakeFirebaseUser(name: null, googleProvider: false),
          ),
        ),
        firestore: _FakeFirebaseFirestore(_FakeCollectionReference(document)),
        googleSignIn: _FakeGoogleSignIn(),
      );

      await expectLater(
        repository.completeGoogleOwnerProfile('Unauthorized Name'),
        throwsA(isA<AuthException>()),
      );
      expect(document.setCalls, isEmpty);
    });

    test('authentication failure does not create a profile', () async {
      final document = _FakeDocumentReference(
        _FakeDocumentSnapshot({}, exists: false),
      );
      final repository = FirebaseAuthRepository(
        auth: _FakeFirebaseAuth(
          _FakeUserCredential(_FakeFirebaseUser()),
          failGoogleSignIn: true,
        ),
        firestore: _FakeFirebaseFirestore(_FakeCollectionReference(document)),
        googleSignIn: _FakeGoogleSignIn(),
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
      expect(document.setCalls, isEmpty);
      expect(document.updates, isEmpty);
    });
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
