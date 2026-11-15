import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/router/owner_access_gate.dart';
import 'package:petcare/app/router/protected_session_gate.dart';
import 'package:petcare/features/profile/domain/entities/user_profile.dart';
import 'package:petcare/features/profile/domain/repositories/profile_repository.dart';
import 'package:petcare/features/profile/presentation/providers/profile_provider.dart';

class _User extends Fake implements User {
  _User(this.uid);

  @override
  final String uid;
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth() : _user = _User('A');

  final _changes = StreamController<User?>.broadcast(sync: true);
  User? _user;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> authStateChanges() => _changes.stream;

  void changeTo(String? uid) {
    _user = uid == null ? null : _User(uid);
    _changes.add(_user);
  }

  Future<void> close() => _changes.close();
}

class _Profiles implements ProfileRepository {
  _Profiles(this.auth);

  final _Auth auth;
  final _streams = <(String, StreamController<UserProfile?>)>[];
  int started = 0;
  int active = 0;
  int cancelled = 0;
  int lastFanout = 0;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    final uid = auth.currentUser!.uid;
    late final StreamController<UserProfile?> stream;
    stream = StreamController<UserProfile?>(
      sync: true,
      onListen: () {
        started++;
        active++;
      },
      onCancel: () {
        active--;
        cancelled++;
      },
    );
    _streams.add((uid, stream));
    return stream.stream;
  }

  void emit(String uid, String role) {
    lastFanout = 0;
    final profile = UserProfile(
      uid: uid,
      fullName: uid,
      displayName: uid,
      email: '',
      phone: '',
      role: role,
      notificationEnabled: true,
    );
    for (final (streamUid, stream) in _streams) {
      if (streamUid == uid && stream.hasListener) {
        lastFanout++;
        stream.add(profile);
      }
    }
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {}

  @override
  Future<void> updateNotificationPreference({required bool enabled}) async {}

  Future<void> close() async {
    for (final (_, stream) in _streams) {
      await stream.close();
    }
  }
}

class _Home extends StatefulWidget {
  const _Home(this.auth, this.profiles);

  final _Auth auth;
  final _Profiles profiles;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late final ProfileProvider provider;

  @override
  void initState() {
    super.initState();
    provider = ProfileProvider(repository: widget.profiles)..startListening();
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('home ${provider.profile?.uid ?? ''}'),
        TextButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ProtectedSessionGate(
                auth: widget.auth,
                sessionUid: 'A',
                childBuilder: (_) => OwnerAccessGate(
                  profileRepository: widget.profiles,
                  childBuilder: (_) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => ProtectedSessionGate(
                            auth: widget.auth,
                            sessionUid: 'A',
                            childBuilder: (_) => OwnerAccessGate(
                              profileRepository: widget.profiles,
                              childBuilder: (_) =>
                                  const Scaffold(body: Text('second')),
                            ),
                          ),
                        ),
                      ),
                      child: const Text('open second'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: const Text('open first'),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'stacked owner gates add subscriptions and disposal cancels them',
    (tester) async {
      final auth = _Auth();
      final profiles = _Profiles(auth);
      addTearDown(() async {
        await profiles.close();
        await auth.close();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ProtectedSessionGate(
            auth: auth,
            sessionUid: 'A',
            childBuilder: (_) => _Home(auth, profiles),
          ),
          routes: {
            '/login': (_) => const Scaffold(body: Text('login')),
            '/home': (_) => const Scaffold(body: Text('new session')),
          },
        ),
      );
      expect(profiles.active, 1);
      profiles.emit('A', 'owner');
      await tester.pump();

      await tester.tap(find.text('open first'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(profiles.active, 2);
      profiles.emit('A', 'owner');
      await tester.pump();

      await tester.tap(find.text('open second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(profiles.active, 3);
      profiles.emit('A', 'owner');
      await tester.pump();
      expect(profiles.lastFanout, 3);
      expect(find.text('second'), findsOneWidget);

      Navigator.of(tester.element(find.text('second'))).pop();
      await tester.pumpAndSettle();
      expect(profiles.active, 2);
      expect(profiles.cancelled, 1);
      profiles.emit('A', 'owner');
      expect(profiles.lastFanout, 2);

      auth.changeTo(null);
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
      expect(profiles.active, 0);
      expect(profiles.cancelled, profiles.started);
      profiles.emit('A', 'owner');
      expect(profiles.lastFanout, 0);
    },
  );
}
