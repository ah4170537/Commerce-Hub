import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class RiderBlockingService {
  Future<void> blockRider(String riderId);
}

class FirestoreRiderBlockingService implements RiderBlockingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreRiderBlockingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> blockRider(String riderId) async {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) {
      throw StateError('Sign in as an administrator before blocking a rider.');
    }

    await _firestore.collection('riders').doc(riderId).update({
      'isBlocked': true,
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedBy': adminId,
    });
  }
}
