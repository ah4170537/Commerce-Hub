import 'package:cloud_firestore/cloud_firestore.dart';

class StoreRider {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? imageUrl;
  final DateTime? createdAt;
  final Map<String, dynamic> details;

  const StoreRider({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.createdAt,
    required this.details,
  });

  factory StoreRider.fromDocument(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return StoreRider(
      id: documentId,
      name: _stringValue(data['fullName'] ?? data['name']) ?? '',
      email: _stringValue(data['email']),
      phone: _stringValue(data['phone'] ?? data['phoneNumber']),
      imageUrl: _stringValue(
        data['profileImageUrl'] ??
            data['photoURL'] ??
            data['photoUrl'] ??
            data['profileImage'] ??
            data['imageUrl'] ??
            data['image'],
      ),
      createdAt: _dateTimeValue(
        data['createdAt'] ?? data['registeredAt'] ?? data['joinedAt'],
      ),
      details: Map.unmodifiable(data),
    );
  }
}

abstract interface class RidersDataSource {
  Stream<List<StoreRider>> watchRiders();
}

class FirestoreRidersDataSource implements RidersDataSource {
  final FirebaseFirestore _firestore;

  FirestoreRidersDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<StoreRider>> watchRiders() {
    return _firestore.collection('riders').snapshots().map((snapshot) {
      final riders = snapshot.docs
          .map(
            (document) => StoreRider.fromDocument(document.id, document.data()),
          )
          .toList();
      riders.sort((first, second) {
        final firstCreatedAt = first.createdAt;
        final secondCreatedAt = second.createdAt;
        if (firstCreatedAt == null) return secondCreatedAt == null ? 0 : 1;
        if (secondCreatedAt == null) return -1;
        return secondCreatedAt.compareTo(firstCreatedAt);
      });
      return riders;
    });
  }
}

String? _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

DateTime? _dateTimeValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
