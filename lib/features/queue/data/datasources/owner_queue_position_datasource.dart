import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/firebase_emulator_config.dart';

/// Requests the signed-in owner's server-calculated waiting position.
///
/// The queue collection is hospital-scoped. Owners cannot read the other
/// entries needed to derive a position safely, so the calculation must happen
/// on the server for the authenticated owner's own queue entry.
abstract interface class OwnerQueuePositionDataSource {
  Future<Map<String, dynamic>> fetchPosition({required String queueId});
}

class FirebaseOwnerQueuePositionDataSource
    implements OwnerQueuePositionDataSource {
  FirebaseOwnerQueuePositionDataSource({
    FirebaseAuth? auth,
    this.client,
    this.endpoint,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final http.Client? client;
  final Uri? endpoint;

  @override
  Future<Map<String, dynamic>> fetchPosition({required String queueId}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to view queue details.');
    final token = await user.getIdToken();
    if (token == null) {
      throw StateError('Your session has expired. Sign in again.');
    }
    final target =
        endpoint ??
        (FirebaseEmulatorConfig.enabled
            ? FirebaseEmulatorConfig.functionEndpoint('getOwnerQueuePosition')
            : Uri.https(
                'asia-south2-${_auth.app.options.projectId}.cloudfunctions.net',
                '/getOwnerQueuePosition',
              ));
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'data': {'queueId': queueId},
    });
    final response =
        await (client != null
                ? client!.post(target, headers: headers, body: body)
                : http.post(target, headers: headers, body: body))
            .timeout(const Duration(seconds: 30));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['error'] != null || response.statusCode != 200) {
      final error = decoded['error'];
      throw StateError(
        error is Map
            ? error['message'] as String? ?? 'Unable to load queue position.'
            : 'Unable to load queue position.',
      );
    }
    return Map<String, dynamic>.from(decoded['result'] as Map);
  }
}
