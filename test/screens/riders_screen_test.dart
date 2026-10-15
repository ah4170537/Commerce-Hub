import 'package:commerce_hub/screens/riders_screen.dart';
import 'package:commerce_hub/services/orders_data_source.dart';
import 'package:commerce_hub/services/riders_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRidersDataSource implements RidersDataSource {
  final List<StoreRider> riders;

  _FakeRidersDataSource(this.riders);

  @override
  Stream<List<StoreRider>> watchRiders() => Stream.value(riders);
}

class _FakeOrdersDataSource implements OrdersDataSource {
  final List<StoreOrder> orders;
  String? requestedRiderId;
  String? requestedRiderPhone;

  _FakeOrdersDataSource(this.orders);

  @override
  Stream<List<StoreOrder>> watchOrders({
    String? customerId,
    String? riderId,
    String? riderPhone,
  }) {
    requestedRiderId = riderId;
    requestedRiderPhone = riderPhone;
    return Stream.value(
      orders
          .where(
            (order) =>
                riderId == null ||
                order.riderId == riderId ||
                order.riderPhone == riderPhone,
          )
          .toList(),
    );
  }

  @override
  Future<void> cancelOrder(StoreOrder order) async {}
}

StoreRider _rider({
  String id = 'rider-7',
  String name = 'Bilal Khan',
  Map<String, dynamic> details = const {},
}) {
  return StoreRider(
    id: id,
    name: name,
    email: 'bilal@example.com',
    phone: '+923001234567',
    imageUrl: null,
    createdAt: null,
    details: details,
  );
}

void main() {
  testWidgets('lists riders and opens their profile details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RidersScreen(
            dataSource: _FakeRidersDataSource([
              _rider(
                details: {
                  'fullName': 'Bilal Khan',
                  'bikeModel': 'Honda CD 70',
                  'licenseNumber': 'DL-12345',
                  'fcmToken': 'private-token',
                },
              ),
              _rider(id: 'rider-8', name: 'Sara Ali'),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riders'), findsOneWidget);
    expect(find.text('Bilal Khan'), findsOneWidget);
    expect(find.text('Sara Ali'), findsOneWidget);

    await tester.tap(find.text('Bilal Khan').first);
    await tester.pumpAndSettle();

    expect(find.text('Rider details'), findsOneWidget);
    expect(find.text('All rider information'), findsOneWidget);
    expect(find.text('Honda CD 70'), findsOneWidget);
    expect(find.text('DL-12345'), findsOneWidget);
    expect(find.text('private-token'), findsNothing);
    expect(find.text('Block rider'), findsOneWidget);
    expect(find.text("Rider's deliveries"), findsOneWidget);
  });

  testWidgets('keeps rider block button without performing a block', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: RiderDetailsScreen(rider: _rider())),
    );

    await tester.tap(find.text('Block rider'));
    await tester.pumpAndSettle();

    expect(find.text('Block rider'), findsOneWidget);
    expect(find.text('Block this rider?'), findsNothing);
    expect(find.text('Blocked'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("opens only this rider's delivered orders", (tester) async {
    final ordersDataSource = _FakeOrdersDataSource([
      StoreOrder.fromDocument('rider-delivery', {
        'status': 'Delivered',
        'riderUid': 'rider-7',
      }),
      StoreOrder.fromDocument('other-rider-delivery', {
        'status': 'Delivered',
        'riderUid': 'rider-8',
      }),
      StoreOrder.fromDocument('rider-active-order', {
        'status': 'Out for Delivery',
        'riderUid': 'rider-7',
      }),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: RiderDetailsScreen(
          rider: _rider(),
          ordersDataSource: ordersDataSource,
        ),
      ),
    );

    await tester.tap(find.text("Rider's deliveries"));
    await tester.pumpAndSettle();

    expect(ordersDataSource.requestedRiderId, 'rider-7');
    expect(ordersDataSource.requestedRiderPhone, '+923001234567');
    expect(find.text('Bilal Khan · Deliveries'), findsOneWidget);
    expect(find.text('Order #rider-delivery'), findsOneWidget);
    expect(find.text('Order #other-rider-delivery'), findsNothing);
    expect(find.text('Order #rider-active-order'), findsNothing);
  });
}
