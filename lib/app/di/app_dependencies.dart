import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.firestore,
    required this.messaging,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseMessaging messaging;

  factory AppDependencies.firebase() {
    return AppDependencies(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      messaging: FirebaseMessaging.instance,
    );
  }
}
