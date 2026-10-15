import 'package:flutter_test/flutter_test.dart';
import 'package:commerce_hub/services/dashboard_data_source.dart';
import 'package:commerce_hub/services/orders_data_source.dart';

void main() {
  group('DashboardOrderCounts.fromStatuses', () {
    test('counts all pending and on-route status labels consistently', () {
      final counts = DashboardOrderCounts.fromStatuses([
        'Placed',
        'Pending',
        'Out for delivery',
        'On route',
        'Delivered',
      ]);

      expect(counts.total, 5);
      expect(counts.pending, 2);
      expect(counts.onRoute, 2);
      expect(counts.delivered, 1);
    });
  });

  group('StoreOrder.fromDocument', () {
    test('parses order product details and calculates line totals', () {
      final order = StoreOrder.fromDocument('order-123', {
        'status': 'Placed',
        'customerName': 'Alex',
        'totalAmount': 1250,
        'items': [
          {
            'productName': 'Coffee',
            'quantity': 2,
            'unitPrice': 500,
            'parts': [
              {'partName': 'Beans', 'specs': 'Dark roast', 'price': 300},
            ],
          },
          {'name': 'Mug', 'qty': 1, 'price': '250'},
        ],
      });

      expect(order.id, 'order-123');
      expect(order.customerName, 'Alex');
      expect(order.total, 1250);
      expect(order.items, hasLength(2));
      expect(order.items[0].name, 'Coffee');
      expect(order.items[0].quantity, 2);
      expect(order.items[0].lineTotal, 1000);
      expect(order.items[0].parts, hasLength(1));
      expect(order.items[0].parts[0].name, 'Beans');
      expect(order.items[0].parts[0].quantity, 1);
      expect(order.items[0].parts[0].specs, 'Dark roast');
      expect(order.items[0].parts[0].price, 300);
      expect(order.items[1].unitPrice, 250);
      expect(order.items[1].lineTotal, 250);
    });

    test('reads parts from an embedded product document', () {
      final order = StoreOrder.fromDocument('order-embedded-product', {
        'items': [
          {
            'quantity': 1,
            'product': {
              'name': 'Gift box',
              'parts': [
                {'partName': 'Ribbon', 'price': 20},
              ],
            },
          },
        ],
      });

      expect(order.items.single.name, 'Gift box');
      expect(order.items.single.parts.single.name, 'Ribbon');
      expect(order.items.single.parts.single.quantity, 1);
      expect(order.items.single.parts.single.price, 20);
    });

    test('reads customer, address, and rider details', () {
      final order = StoreOrder.fromDocument('delivery-123', {
        'status': 'On route',
        'fullName': 'Ahmad Haseeb',
        'email': 'alex@example.com',
        'phone': '555-0100',
        'address': 'F66W+XJV, Ali Town Lahore, Pakistan',
        'city': 'Lahore',
        'country': 'Pakistan',
        'state': 'Punjab',
        'postalCode': '12453',
        'riderUid': 'rider-7',
      });

      expect(order.customerName, 'Ahmad Haseeb');
      expect(order.customerEmail, 'alex@example.com');
      expect(order.customerPhone, '555-0100');
      expect(
        order.deliveryAddress,
        'F66W+XJV, Ali Town Lahore, Pakistan, Punjab, 12453',
      );
      expect(order.riderId, 'rider-7');
    });

    test('resolves the owning customer from the order document', () {
      final order = StoreOrder.fromDocument('order-456', {
        'userId': 'customer-123',
      }, ownerId: 'customer-123');

      expect(order.customerId, 'customer-123');
    });

    test('uses the owning user document as the customer ID', () {
      final order = StoreOrder.fromDocument('order-456', {
        'userId': 'stale-user-id',
      }, ownerId: 'customer-123');

      expect(order.customerId, 'customer-123');
    });
  });

  group('RiderDetails.fromDocument', () {
    test('reads rider contact and vehicle fields from the rider document', () {
      final rider = RiderDetails.fromDocument('rider-7', {
        'uid': 'rider-7',
        'fullName': 'Bilal',
        'phone': '+923123210230',
        'secondaryPhone': '',
        'email': 'bilal@example.com',
        'bikeModel': 'honda cd 70',
        'bikeNumber': 'LHE1212',
        'city': 'Lahore',
      });

      expect(rider.id, 'rider-7');
      expect(rider.fullName, 'Bilal');
      expect(rider.phone, '+923123210230');
      expect(rider.secondaryPhone, isNull);
      expect(rider.bikeModel, 'honda cd 70');
      expect(rider.bikeNumber, 'LHE1212');
      expect(rider.city, 'Lahore');
    });
  });

  group('StoreOrder.matchesStatus', () {
    test('maps placed orders to pending', () {
      final order = StoreOrder.fromDocument('one', {'status': 'Placed'});

      expect(order.matchesStatus(OrderStatusFilter.pending), isTrue);
      expect(order.matchesStatus(OrderStatusFilter.onRoute), isFalse);
    });

    test('matches on-route and delivered status labels', () {
      final onRoute = StoreOrder.fromDocument('two', {
        'status': 'Out for Delivery',
      });
      final delivered = StoreOrder.fromDocument('three', {
        'status': 'delivered',
      });

      expect(onRoute.matchesStatus(OrderStatusFilter.onRoute), isTrue);
      expect(delivered.matchesStatus(OrderStatusFilter.delivered), isTrue);
      expect(delivered.matchesStatus(OrderStatusFilter.all), isTrue);
    });

    test('only placed and pending orders are cancellable', () {
      final placed = StoreOrder.fromDocument('one', {'status': 'Placed'});
      final pending = StoreOrder.fromDocument('two', {'status': 'Pending'});
      final onRoute = StoreOrder.fromDocument('three', {'status': 'On route'});
      final delivered = StoreOrder.fromDocument('four', {
        'status': 'Delivered',
      });

      expect(placed.isPending, isTrue);
      expect(pending.isPending, isTrue);
      expect(onRoute.isPending, isFalse);
      expect(delivered.isPending, isFalse);
    });
  });
}
