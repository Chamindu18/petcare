import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_schedule.dart';

abstract interface class LocalReminderNotifications {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<List<PendingNotificationRequest>> pendingRequests();
  Future<void> cancel(int id);
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
  });
}

class AndroidLocalReminderNotifications implements LocalReminderNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;

  @override
  Future<List<PendingNotificationRequest>> pendingRequests() =>
      _plugin.pendingNotificationRequests();

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
  }) => _plugin.zonedSchedule(
    id,
    title,
    body,
    when,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'petcare_owner_reminders',
        'PetCare+ reminders',
        channelDescription: 'Appointment and vaccination reminders',
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: payload,
  );
}

/// Reconciles Android local reminders from the signed-in owner's Firestore
/// records. No pet or appointment data is read for a different account.
class OwnerReminderService {
  OwnerReminderService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    LocalReminderNotifications? notifications,
    Future<String> Function()? timezoneName,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _notifications = notifications ?? AndroidLocalReminderNotifications(),
       _timezoneName = timezoneName ?? _deviceTimezoneName;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final LocalReminderNotifications _notifications;
  final Future<String> Function() _timezoneName;

  static Future<String> _deviceTimezoneName() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _appointmentSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _petSubscription;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _vaccinationSubscriptions = {};
  final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _vaccinations = {};
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _appointments = [];
  Map<String, String> _petNames = {};
  String? _uid;
  bool _enabled = false;
  bool _initialized = false;
  bool _permissionGranted = false;
  int _generation = 0;
  Future<void> _pendingWork = Future.value();

  Future<void> start() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _notifications.initialize();
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await _timezoneName()));
    } catch (error) {
      debugPrint('Reminder timezone unavailable: $error');
      return;
    }
    _initialized = true;
    _authSubscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _uid) return;
    final generation = ++_generation;
    _profileSubscription?.cancel();
    _appointmentSubscription?.cancel();
    _petSubscription?.cancel();
    for (final subscription in _vaccinationSubscriptions.values) {
      subscription.cancel();
    }
    _vaccinationSubscriptions.clear();
    _vaccinations.clear();
    _appointments = [];
    _petNames = {};
    _uid = uid;
    _enabled = false;
    _permissionGranted = false;
    _enqueue(() => _cancelManagedReminders(generation, keepUid: uid));
    if (uid == null) return;
    _profileSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((document) {
          if (generation != _generation) return;
          final enabled =
              document.data()?['role'] == 'owner' &&
              document.data()?['notificationEnabled'] != false;
          _enabled = enabled;
          if (enabled) {
            _enqueue(() async {
              if (generation != _generation) return;
              _permissionGranted = await _notifications.requestPermission();
              await _reconcile(generation);
            });
          } else {
            _enqueue(() => _cancelManagedReminders(generation, onlyUid: uid));
          }
        });
    _appointmentSubscription = _firestore
        .collection('appointments')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          if (generation != _generation) return;
          _appointments = snapshot.docs;
          _enqueue(() => _reconcile(generation));
        });
    _petSubscription = _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          if (generation != _generation) return;
          _petNames = {
            for (final pet in snapshot.docs)
              pet.id: (pet.data()['name'] as String?) ?? 'your pet',
          };
          final removed = _vaccinationSubscriptions.keys
              .where((petId) => !_petNames.containsKey(petId))
              .toList();
          for (final petId in removed) {
            _vaccinationSubscriptions.remove(petId)?.cancel();
            _vaccinations.remove(petId);
          }
          for (final petId in _petNames.keys) {
            if (_vaccinationSubscriptions.containsKey(petId)) continue;
            _vaccinationSubscriptions[petId] = _firestore
                .collection('vaccinations')
                .where('petId', isEqualTo: petId)
                .snapshots()
                .listen((vaccinations) {
                  if (generation != _generation) return;
                  _vaccinations[petId] = vaccinations.docs;
                  _enqueue(() => _reconcile(generation));
                });
          }
          _enqueue(() => _reconcile(generation));
        });
  }

  Future<void> _reconcile(int generation) async {
    if (!_initialized ||
        !_enabled ||
        !_permissionGranted ||
        generation != _generation ||
        _uid == null) {
      return;
    }
    final uid = _uid!;
    await _cancelManagedReminders(generation, onlyUid: uid);
    if (generation != _generation || !_enabled) return;
    final now = DateTime.now();
    for (final appointment in _appointments) {
      if (generation != _generation || !_enabled) return;
      final data = appointment.data();
      if (data['ownerId'] != uid || data['status'] != 'confirmed') continue;
      final rawDate = data['dateTime'];
      final date = rawDate is Timestamp
          ? rawDate.toDate()
          : DateTime.tryParse(rawDate is String ? rawDate : '');
      if (date == null) continue;
      final when = ReminderSchedule.appointment(date, now);
      if (when == null) continue;
      await _schedule(
        uid: uid,
        kind: 'appointment',
        documentId: appointment.id,
        when: when,
        title: 'Appointment tomorrow',
        body: 'Your confirmed veterinary appointment is in 24 hours.',
      );
    }
    for (final entry in _vaccinations.entries) {
      if (!_petNames.containsKey(entry.key)) continue;
      for (final vaccination in entry.value) {
        if (generation != _generation || !_enabled) return;
        final data = vaccination.data();
        if (data['petId'] != entry.key) continue;
        final rawDue = data['nextDueDate'];
        final due = rawDue is String ? DateTime.tryParse(rawDue) : null;
        if (due == null) continue;
        final when = ReminderSchedule.vaccination(due, now);
        if (when == null) continue;
        await _schedule(
          uid: uid,
          kind: 'vaccination',
          documentId: vaccination.id,
          when: when,
          title: 'Vaccination due soon',
          body: '${_petNames[entry.key]} has a vaccination due tomorrow.',
        );
      }
    }
  }

  Future<void> _schedule({
    required String uid,
    required String kind,
    required String documentId,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    final payload = 'petcare-owner:$uid:$kind:$documentId';
    var hash = 0x811c9dc5;
    for (final unit in payload.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    await _notifications.schedule(
      id: hash,
      title: title,
      body: body,
      when: tz.TZDateTime.from(when, tz.local),
      payload: payload,
    );
  }

  void _enqueue(Future<void> Function() action) {
    _pendingWork = _pendingWork.then((_) => action()).catchError((
      Object error,
    ) {
      debugPrint('Unable to reconcile reminders: $error');
    });
  }

  Future<void> _cancelManagedReminders(
    int generation, {
    String? onlyUid,
    String? keepUid,
  }) async {
    final pending = await _notifications.pendingRequests();
    for (final request in pending) {
      final payload = request.payload;
      if (payload?.startsWith('petcare-owner:') == true &&
          (onlyUid == null || payload!.startsWith('petcare-owner:$onlyUid:')) &&
          (keepUid == null ||
              !payload!.startsWith('petcare-owner:$keepUid:'))) {
        await _notifications.cancel(request.id);
      }
    }
    if (generation != _generation) return;
  }

  void dispose() {
    _generation++;
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _appointmentSubscription?.cancel();
    _petSubscription?.cancel();
    for (final subscription in _vaccinationSubscriptions.values) {
      subscription.cancel();
    }
  }
}
