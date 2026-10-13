import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemPart {
  final String name;
  final int quantity;
  final String? specs;
  final num? price;

  const OrderItemPart({
    required this.name,
    required this.quantity,
    required this.specs,
    required this.price,
  });

  factory OrderItemPart.fromMap(Map<String, dynamic> data, int index) {
    final quantity = _numberValue(
      data['quantity'] ?? data['qty'] ?? data['count'] ?? 1,
    )?.toInt() ?? 1;

    return OrderItemPart(
      name:
          _stringValue(
            data['partName'] ?? data['name'] ?? data['productName'],
          ) ??
          'Part ${index + 1}',
      quantity: quantity,
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
  final String? customerEmail;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? riderName;
  final String? riderPhone;
  final String? riderId;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final num? total;
  final DocumentReference<Map<String, dynamic>>? reference;

  const StoreOrder({
    required this.id,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.riderName,
    required this.riderPhone,
    required this.riderId,
    required this.createdAt,
    required this.items,
    required this.total,
    this.reference,
  });

  factory StoreOrder.fromDocument(
    String documentId,
    Map<String, dynamic> data,
    {DocumentReference<Map<String, dynamic>>? reference}
  ) {
    final riderValue = data['rider'] ?? data['deliveryRider'];
    final riderData = riderValue is Map
        ? Map<String, dynamic>.from(riderValue)
        : const <String, dynamic>{};
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
        data['customerName'] ??
            data['userName'] ??
            data['fullName'] ??
            data['name'],
      ),
      customerEmail: _stringValue(
        data['customerEmail'] ?? data['email'],
      ),
      customerPhone: _stringValue(
        data['customerPhone'] ?? data['phoneNumber'] ?? data['phone'],
      ),
      deliveryAddress: _addressValue(
        data['deliveryAddress'] ??
            data['shippingAddress'] ??
            data['address'],
        city: data['city'],
        state: data['state'],
        postalCode: data['postalCode'],
        country: data['country'],
      ),
      riderName: _stringValue(
        riderData['name'] ??
            riderData['riderName'] ??
            data['riderName'] ??
            data['deliveryRiderName'],
      ),
      riderPhone: _stringValue(
        riderData['phone'] ??
            riderData['phoneNumber'] ??
            data['riderPhone'] ??
            data['deliveryRiderPhone'],
      ),
      riderId: _stringValue(
        riderData['id'] ??
            riderData['uid'] ??
            riderData['riderId'] ??
            data['riderId'] ??
            data['riderUid'],
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
      reference: reference,
    );
  }

  bool get isPending => matchesStatus(OrderStatusFilter.pending);

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

class RiderDetails {
  final String id;
  final String? fullName;
  final String? phone;
  final String? secondaryPhone;
  final String? email;
  final String? bikeModel;
  final String? bikeNumber;
  final String? city;

  const RiderDetails({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.secondaryPhone,
    required this.email,
    required this.bikeModel,
    required this.bikeNumber,
    required this.city,
  });

  factory RiderDetails.fromDocument(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return RiderDetails(
      id: _stringValue(data['uid']) ?? documentId,
      fullName: _stringValue(data['fullName'] ?? data['name']),
      phone: _stringValue(data['phone'] ?? data['phoneNumber']),
      secondaryPhone: _stringValue(data['secondaryPhone']),
      email: _stringValue(data['email']),
      bikeModel: _stringValue(data['bikeModel']),
      bikeNumber: _stringValue(data['bikeNumber']),
      city: _stringValue(data['city']),
    );
  }
}

abstract interface class RiderDetailsDataSource {
  Future<RiderDetails?> getRiderDetails(String riderId);
}

class FirestoreRiderDetailsDataSource implements RiderDetailsDataSource {
  final FirebaseFirestore _firestore;

  FirestoreRiderDetailsDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<RiderDetails?> getRiderDetails(String riderId) async {
    final snapshot = await _firestore.collection('riders').doc(riderId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return RiderDetails.fromDocument(snapshot.id, data);
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
  Future<void> cancelOrder(StoreOrder order);
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
                        StoreOrder.fromDocument(
                          document.id,
                          document.data(),
                          reference: document.reference,
                        ),
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

  @override
  Future<void> cancelOrder(StoreOrder order) async {
    if (!order.isPending) {
      throw StateError('Only pending orders can be cancelled.');
    }
    final reference = order.reference;
    if (reference == null) {
      throw StateError('This order is not linked to a Firestore document.');
    }

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final status = _stringValue(snapshot.data()?['status'])?.toLowerCase();
      if (status != 'placed' && status != 'pending') {
        throw StateError('This order is no longer pending and cannot be cancelled.');
      }
      transaction.update(reference, {'status': 'Cancelled'});
    });
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

String? _addressValue(
  Object? value, {
  Object? city,
  Object? state,
  Object? postalCode,
  Object? country,
}) {
  final addressParts = <String>[];
  if (value is String) {
    final address = _stringValue(value);
    if (address != null) addressParts.add(address);
  } else if (value is Map) {
    final address = Map<String, dynamic>.from(value);
    addressParts.addAll(
      [
        address['addressLine1'] ?? address['street'] ?? address['line1'],
        address['addressLine2'] ?? address['line2'],
        address['city'],
        address['state'] ?? address['province'],
        address['postalCode'] ?? address['zipCode'],
        address['country'],
      ].map(_stringValue).whereType<String>(),
    );
  }

  for (final part in [city, state, postalCode, country]
      .map(_stringValue)
      .whereType<String>()) {
    if (!addressParts.join(', ').toLowerCase().contains(part.toLowerCase())) {
      addressParts.add(part);
    }
  }
  return addressParts.isEmpty ? null : addressParts.join(', ');
}
