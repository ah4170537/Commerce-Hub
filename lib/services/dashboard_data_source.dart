import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardOrderCounts {
  final int total;
  final int pending;
  final int onRoute;
  final int delivered;

  const DashboardOrderCounts({
    required this.total,
    required this.pending,
    required this.onRoute,
    required this.delivered,
  });

  factory DashboardOrderCounts.fromStatuses(Iterable<Object?> statuses) {
    var total = 0;
    var pending = 0;
    var onRoute = 0;
    var delivered = 0;

    for (final rawStatus in statuses) {
      total++;
      final status = rawStatus is String ? rawStatus.trim().toLowerCase() : '';

      switch (status) {
        case 'placed':
          pending++;
        case 'out for delivery':
          onRoute++;
        case 'delivered':
          delivered++;
      }
    }

    return DashboardOrderCounts(
      total: total,
      pending: pending,
      onRoute: onRoute,
      delivered: delivered,
    );
  }
}

abstract interface class DashboardDataSource {
  Stream<int> watchCustomerCount();
  Stream<DashboardOrderCounts> watchOrderCounts();
}

class FirestoreDashboardDataSource implements DashboardDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDashboardDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<int> watchCustomerCount() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Stream<DashboardOrderCounts> watchOrderCounts() {
    return _firestore.collectionGroup('user_orders').snapshots().map(
      (snapshot) => DashboardOrderCounts.fromStatuses(
        snapshot.docs.map((order) => order.data()['status']),
      ),
    );
  }
}
