import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/veterinarian.dart';
import '../../domain/repositories/veterinarian_assignment_repository.dart';
import '../models/veterinarian_model.dart';

class FirebaseVeterinarianAssignmentRepository
    implements VeterinarianAssignmentRepository {
  FirebaseVeterinarianAssignmentRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<Veterinarian?> getCurrentAssignment() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final user = (await _firestore.doc('users/$uid').get()).data();
    if (user?['role'] != 'veterinarian') return null;
    final vetId = user?['vetId'] ?? uid;
    final hospitalId = user?['hospitalId'];
    if (vetId is! String ||
        vetId.isEmpty ||
        hospitalId is! String ||
        hospitalId.isEmpty ||
        hospitalId == 'unassigned') {
      return null;
    }
    final data = (await _firestore.collection('veterinarians').doc(vetId).get())
        .data();
    if (data == null ||
        data['userId'] != uid ||
        data['active'] != true ||
        data['hospitalId'] != hospitalId ||
        (data.containsKey('vetId') && data['vetId'] != vetId)) {
      return null;
    }
    return VeterinarianModel.fromMap({...data, 'vetId': vetId});
  }
}
