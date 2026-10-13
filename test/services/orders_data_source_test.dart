import 'package:flutter_test/flutter_test.dart';
import 'package:commerce_hub/services/orders_data_source.dart';

void main() {
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
      expect(order.items.single.parts.single.price, 20);
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
  });
}
