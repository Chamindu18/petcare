import 'package:firebase_core/firebase_core.dart';

/// Compile-time configuration for the isolated academic demo environment.
///
/// Emulator mode is opt-in. Release and ordinary debug builds continue to use
/// the generated production Firebase options unless the explicit dart define
/// is supplied.
abstract final class FirebaseEmulatorConfig {
  static const enabled = bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  /// Android Emulator reaches the development machine through 10.0.2.2.
  /// A physical device using `adb reverse` should override this with
  /// FIREBASE_EMULATOR_HOST=127.0.0.1.
  static const host = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );

  static const projectId = 'demo-petcare';
  static const authPort = 9099;
  static const firestorePort = 8080;
  static const functionsPort = 5001;
  static const functionsRegion = 'asia-south2';

  /// Synthetic options keep emulator documents and Auth users in the
  /// demo-petcare namespace rather than the shared petcare-d4413 project.
  static const firebaseOptions = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:android:petcare-demo',
    messagingSenderId: '1234567890',
    projectId: projectId,
  );

  static Uri functionEndpoint(String functionName) => Uri.http(
    '$host:$functionsPort',
    '/$projectId/$functionsRegion/$functionName',
  );
}
