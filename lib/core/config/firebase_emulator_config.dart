import 'package:firebase_core/firebase_core.dart';

/// Compile-time configuration for the isolated academic demo environment.
///
/// Emulator mode is opt-in. Release and ordinary debug builds continue
/// to use production Firebase options unless explicitly enabled.
abstract final class FirebaseEmulatorConfig {
  static const bool enabled = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  /// Android Studio Emulator: 10.0.2.2
  /// Physical Android phone with adb reverse: 127.0.0.1
  ///
  /// Override using --dart-define=FIREBASE_EMULATOR_HOST=...
  static const String host = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );

  /// Prevent FlutterFire from remapping localhost to 10.0.2.2.
  ///
  /// Safe for both explicitly configured Android emulator hosts
  /// and physical devices connected through adb reverse.
  static const bool automaticHostMapping = false;

  static const String projectId = 'demo-petcare';

  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int functionsPort = 5001;

  static const String functionsRegion = 'asia-south2';

  /// Synthetic Firebase options for the isolated emulator project.
  ///
  /// Never use these options for production Firebase connections.
  static const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:android:petcare-demo',
    messagingSenderId: '1234567890',
    projectId: projectId,
  );

  /// Returns the local callable endpoint.
  static Uri functionEndpoint(String functionName) {
    return Uri.http(
      '$host:$functionsPort',
      '/$projectId/$functionsRegion/$functionName',
    );
  }
}
