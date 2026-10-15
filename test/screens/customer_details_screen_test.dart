import 'package:commerce_hub/screens/customer_details_screen.dart';
import 'package:commerce_hub/services/customers_data_source.dart';
import 'package:commerce_hub/services/orders_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOrdersDataSource implements OrdersDataSource {
  final List<StoreOrder> orders;
  String? requestedCustomerId;

  _FakeOrdersDataSource(this.orders);

  @override
  Stream<List<StoreOrder>> watchOrders({
    String? customerId,
    String? riderId,
    String? riderPhone,
  }) {
    requestedCustomerId = customerId;
    return Stream.value(
      orders
          .where(
            (order) => customerId == null || order.customerId == customerId,
          )
          .toList(),
    );
  }

  @override
  Future<void> cancelOrder(StoreOrder order) async {}
}

void main() {
  testWidgets('hides customer ID, coordinates, and profile image URL', (
    tester,
  ) async {
    final customer = StoreCustomer(
      id: 'private-customer-id',
      name: 'Alex Rivera',
      email: null,
      phone: null,
      imageUrl: null,
      createdAt: null,
      details: {
        'name': 'Alex Rivera',
        'uid': 'private-uid',
        'latitude': 30.15,
        'longitude': 70.2,
        'profileImageUrl': 'https://example.com/private-profile.jpg',
        'fcmToken': 'private-fcm-token',
        'shippingAddress': {
          'address': 'Street 7',
          'city': 'Burewala',
          'latitude': 30.15,
          'longitude': 70.2,
        },
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: CustomerDetailsScreen(customer: customer)),
    );

    expect(find.text('Alex Rivera'), findsWidgets);
    expect(find.text('Street 7'), findsOneWidget);
    expect(find.text('Burewala'), findsOneWidget);
    expect(find.text('private-customer-id'), findsNothing);
    expect(find.text('private-uid'), findsNothing);
    expect(find.text('30.15'), findsNothing);
    expect(find.text('70.2'), findsNothing);
    expect(find.text('https://example.com/private-profile.jpg'), findsNothing);
    expect(find.text('private-fcm-token'), findsNothing);
    expect(find.text("User's orders"), findsOneWidget);
    expect(find.text('Block customer'), findsOneWidget);
  });

  testWidgets('keeps customer block button without performing a block', (
    tester,
  ) async {
    final customer = StoreCustomer(
      id: 'customer-123',
      name: 'Alex Rivera',
      email: null,
      phone: null,
      imageUrl: null,
      createdAt: null,
    );

    await tester.pumpWidget(
      MaterialApp(home: CustomerDetailsScreen(customer: customer)),
    );

    await tester.tap(find.text('Block customer'));
    await tester.pumpAndSettle();

    expect(find.text('Block customer'), findsOneWidget);
    expect(find.text('Block this customer?'), findsNothing);
    expect(find.text('Blocked'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("opens this customer's filtered orders", (tester) async {
    final customer = StoreCustomer(
      id: 'customer-123',
      name: 'Alex Rivera',
      email: null,
      phone: null,
      imageUrl: null,
      createdAt: null,
    );
    final ordersDataSource = _FakeOrdersDataSource([
      StoreOrder.fromDocument('alex-order', {
        'status': 'Placed',
        'customerName': 'Alex Rivera',
      }, ownerId: 'customer-123'),
      StoreOrder.fromDocument('other-order', {
        'status': 'Placed',
        'customerName': 'Other customer',
      }, ownerId: 'customer-456'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailsScreen(
          customer: customer,
          ordersDataSource: ordersDataSource,
        ),
      ),
    );
    await tester.tap(find.text("User's orders"));
    await tester.pumpAndSettle();

    expect(ordersDataSource.requestedCustomerId, 'customer-123');
    expect(find.text('Alex Rivera · Orders'), findsOneWidget);
    expect(find.text('Order #alex-order'), findsOneWidget);
    expect(find.text('Order #other-order'), findsNothing);
  });
}
