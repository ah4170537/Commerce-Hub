import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemPart {
  final String name;
  final String? specs;
  final num? price;

  const OrderItemPart({
    required this.name,
    required this.specs,
    required this.price,
  });

  factory OrderItemPart.fromMap(Map<String, dynamic> data, int index) {
    return OrderItemPart(
      name:
          _stringValue(
            data['partName'] ?? data['name'] ?? data['productName'],
          ) ??
          'Part ${index + 1}',
      specs: _stringValue(data['specs'] ?? data['description']),
      price: _numberValue(data['price'] ?? data['unitPrice']),
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final num? unitPrice;
  final num? lineTotal;
  final List<OrderItemPart> parts;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.parts,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data, int index) {
    final product = data['product'];
    final productData = product is Map
        ? Map<String, dynamic>.from(product)
        : const <String, dynamic>{};
    final rawParts = data['parts'] ?? productData['parts'];
    final quantity = _numberValue(
      data['quantity'] ?? data['qty'] ?? data['count'],
    );
    final unitPrice = _numberValue(
      data['unitPrice'] ??
          data['price'] ??
          productData['unitPrice'] ??
          productData['price'],
    );
    final parts = rawParts is List
        ? rawParts
              .asMap()
              .entries
              .where((entry) => entry.value is Map)
              .map(
                (entry) => OrderItemPart.fromMap(
                  Map<String, dynamic>.from(entry.value as Map),
                  entry.key,
                ),
              )
              .toList()
        : const <OrderItemPart>[];

    return OrderItem(
      name:
          _stringValue(
            data['productName'] ??
                data['name'] ??
                data['title'] ??
                productData['name'] ??
                productData['productName'],
          ) ??
          'Product ${index + 1}',
      quantity: quantity?.toInt() ?? 1,
      unitPrice: unitPrice,
      lineTotal:
          _numberValue(data['lineTotal'] ?? data['subtotal']) ??
          (unitPrice == null ? null : unitPrice * (quantity ?? 1)),
      parts: parts,
    );
  }
}

class StoreOrder {
  final String id;
  final String status;
  final String? customerName;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final num? total;

  const StoreOrder({
    required this.id,
    required this.status,
    required this.customerName,
    required this.createdAt,
    required this.items,
    required this.total,
  });

  factory StoreOrder.fromDocument(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final rawItems = data['items'] ?? data['orderItems'] ?? data['products'];
    final items = rawItems is List
        ? rawItems
              .asMap()
              .entries
              .where((entry) => entry.value is Map)
              .map(
                (entry) => OrderItem.fromMap(
                  Map<String, dynamic>.from(entry.value as Map),
                  entry.key,
                ),
              )
              .toList()
        : const <OrderItem>[];

    return StoreOrder(
      id: documentId,
      status: _stringValue(data['status']) ?? 'Unknown',
      customerName: _stringValue(
        data['customerName'] ?? data['userName'] ?? data['name'],
      ),
      createdAt: _dateTimeValue(
        data['createdAt'] ?? data['orderDate'] ?? data['timestamp'],
      ),
      items: items,
      total: _numberValue(
        data['totalAmount'] ??
            data['grandTotal'] ??
            data['total'] ??
            data['amountDue'],
      ),
    );
  }

  bool matchesStatus(OrderStatusFilter filter) {
    final normalizedStatus = status.trim().toLowerCase();
    switch (filter) {
      case OrderStatusFilter.all:
        return true;
      case OrderStatusFilter.pending:
        return normalizedStatus == 'placed' || normalizedStatus == 'pending';
      case OrderStatusFilter.onRoute:
        return normalizedStatus == 'out for delivery' ||
            normalizedStatus == 'on route';
      case OrderStatusFilter.delivered:
        return normalizedStatus == 'delivered';
    }
  }
}

enum OrderStatusFilter {
  all('All'),
  pending('Pending'),
  onRoute('On route'),
  delivered('Delivered');

  final String label;

  const OrderStatusFilter(this.label);
}

abstract interface class OrdersDataSource {
  Stream<List<StoreOrder>> watchOrders();
}

class FirestoreOrdersDataSource implements OrdersDataSource {
  final FirebaseFirestore _firestore;

  FirestoreOrdersDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<StoreOrder>> watchOrders() {
    return _firestore
        .collectionGroup('user_orders')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (document) =>
                        StoreOrder.fromDocument(document.id, document.data()),
                  )
                  .toList()
                ..sort((first, second) {
                  final firstDate = first.createdAt;
                  final secondDate = second.createdAt;
                  if (firstDate == null) return 1;
                  if (secondDate == null) return -1;
                  return secondDate.compareTo(firstDate);
                }),
        );
  }
}

String? _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

num? _numberValue(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

DateTime? _dateTimeValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
