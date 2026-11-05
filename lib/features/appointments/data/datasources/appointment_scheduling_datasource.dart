import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/firebase_emulator_config.dart';

/// The server is the only scheduling writer; availability reads are advisory.
abstract interface class AppointmentSchedulingDataSource {
  Future<Map<String, dynamic>> reserve(Map<String, dynamic> request);
}

class FirebaseAppointmentSchedulingDataSource
    implements AppointmentSchedulingDataSource {
  FirebaseAppointmentSchedulingDataSource({
    FirebaseAuth? auth,
    this.client,
    this.endpoint,
  }) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;
  final http.Client? client;
  final Uri? endpoint;

  @override
  Future<Map<String, dynamic>> reserve(Map<String, dynamic> request) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to manage appointments.');
    final token = await user.getIdToken();
    if (token == null) {
      throw StateError('Your session has expired. Sign in again.');
    }
    final target = endpoint ??
        (FirebaseEmulatorConfig.enabled
            ? FirebaseEmulatorConfig.functionEndpoint(
                'reserveAppointmentSlot',
              )
            : Uri.https(
                'asia-south2-${_auth.app.options.projectId}.cloudfunctions.net',
                '/reserveAppointmentSlot',
              ));
    // Follow the Firebase callable protocol using the existing HTTP dependency.
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({'data': request});
    final response =
        await (client != null
                ? client!.post(target, headers: headers, body: body)
                : http.post(target, headers: headers, body: body))
            .timeout(const Duration(seconds: 60));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['error'] != null || response.statusCode != 200) {
      final error = decoded['error'];
      throw StateError(
        error is Map
            ? error['message'] as String? ?? 'Unable to reserve appointment.'
            : 'Unable to reserve appointment.',
      );
    }
    return Map<String, dynamic>.from(decoded['result'] as Map);
  }
}
