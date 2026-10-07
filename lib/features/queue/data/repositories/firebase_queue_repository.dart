import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/queue.dart';
import '../../domain/repositories/queue_repository.dart';
import '../models/queue_model.dart';

/// Reads queue information from Firestore.
class FirebaseQueueRepository implements QueueRepository {
  FirebaseQueueRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Reference to the queue records collection.
  CollectionReference<Map<String, dynamic>> get _queueCollection =>
      _firestore.collection('queue_records');

  @override
  Future<Queue?> getQueueByAppointment(String appointmentId) async {
    // Find the queue linked to this appointment.
    final snapshot = await _queueCollection
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return QueueModel.fromMap(snapshot.docs.first.data());
  }

  @override
  Future<Queue?> getQueueById(String queueId) async {
    // Get one queue record by its document ID.
    final document = await _queueCollection.doc(queueId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null) {
      return null;
    }

    return QueueModel.fromMap(data);
  }
}
