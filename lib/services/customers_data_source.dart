import 'package:cloud_firestore/cloud_firestore.dart';

class StoreCustomer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? imageUrl;
  final DateTime? createdAt;
  final Map<String, dynamic> details;

  const StoreCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.createdAt,
    this.details = const {},
  });

  factory StoreCustomer.fromDocument(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return StoreCustomer(
      id: documentId,
      name:
          _stringValue(
            data['fullName'] ?? data['displayName'] ?? data['name'],
          ) ??
          '',
      email: _stringValue(data['email']),
      phone: _stringValue(data['phoneNumber'] ?? data['phone']),
      imageUrl: _stringValue(
        data['profileImageUrl'] ??
            data['photoURL'] ??
            data['photoUrl'] ??
            data['profileImage'] ??
            data['imageUrl'] ??
            data['image'],
      ),
      createdAt: _dateTimeValue(data['createdAt']),
      details: Map.unmodifiable(data),
    );
  }

  static String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static DateTime? _dateTimeValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

abstract interface class CustomersDataSource {
  Stream<List<StoreCustomer>> watchCustomers();
}

class FirestoreCustomersDataSource implements CustomersDataSource {
  final FirebaseFirestore _firestore;

  FirestoreCustomersDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<StoreCustomer>> watchCustomers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final customers = snapshot.docs
          .map(
            (document) =>
                StoreCustomer.fromDocument(document.id, document.data()),
          )
          .where((customer) => customer.name.isNotEmpty)
          .toList();
      customers.sort((first, second) {
        final firstCreatedAt = first.createdAt;
        final secondCreatedAt = second.createdAt;
        if (firstCreatedAt == null) return secondCreatedAt == null ? 0 : 1;
        if (secondCreatedAt == null) return -1;
        return secondCreatedAt.compareTo(firstCreatedAt);
      });
      return customers;
    });
  }
}
