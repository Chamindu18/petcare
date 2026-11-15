import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/core/config/firebase_emulator_config.dart';

void main() {
  test('emulator endpoints follow the explicit Android host', () {
    const expectedHost = String.fromEnvironment(
      'EXPECTED_EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    );
    const expectedEnabled = bool.fromEnvironment('EXPECT_EMULATORS');

    expect(FirebaseEmulatorConfig.enabled, expectedEnabled);
    expect(FirebaseEmulatorConfig.host, expectedHost);
    expect(FirebaseEmulatorConfig.automaticHostMapping, isFalse);
    expect(FirebaseEmulatorConfig.firebaseOptions.projectId, 'demo-petcare');
    expect(FirebaseEmulatorConfig.authPort, 9099);
    expect(FirebaseEmulatorConfig.firestorePort, 8080);
    expect(
      FirebaseEmulatorConfig.functionEndpoint('getOwnerQueuePosition'),
      Uri.parse(
        'http://$expectedHost:5001/demo-petcare/asia-south2/'
        'getOwnerQueuePosition',
      ),
    );
  });
}
