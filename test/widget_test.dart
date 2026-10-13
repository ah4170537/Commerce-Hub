// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:commerce_hub/screens/dashboard_screen.dart';
import 'package:commerce_hub/screens/products_screen.dart';
import 'package:commerce_hub/services/dashboard_data_source.dart';
import 'package:commerce_hub/services/products_data_source.dart';

class _FakeDashboardDataSource implements DashboardDataSource {
  @override
  Stream<int> watchCustomerCount() => Stream.value(4);

  @override
  Stream<DashboardOrderCounts> watchOrderCounts() {
    return Stream.value(
      const DashboardOrderCounts(
        total: 7,
        pending: 2,
        onRoute: 1,
        delivered: 3,
      ),
    );
  }
}

class _FakeProductsDataSource implements ProductsDataSource {
  @override
  Stream<List<StoreProduct>> watchProducts() {
    return Stream.value([
      StoreProduct.fromDocument('prod-102', {
        'name': 'Flagship Smartphone Unit',
        'category': 'components',
        'subCategory': 'machine_assembly',
        'price': 140000,
        'variants': [
          {'name': 'Standard Unit', 'price': 140000},
        ],
        'parts': [
          {
            'partName': 'Battery Module',
            'price': 8000,
            'specs': '5000mAh Li-Po',
          },
        ],
      }),
    ]);
  }
}

void main() {
  test('parses standard products and optional component fields', () {
    final product = StoreProduct.fromDocument('fallback-id', {
      'id': 'prod-102',
      'name': 'Flagship Smartphone Unit',
      'category': 'components',
      'price': 140000,
      'imageUrls': ['https://example.com/image.jpg'],
      'parts': [
        {'partName': 'Battery Module', 'price': 8000, 'specs': '5000mAh Li-Po'},
      ],
    });

    expect(product.id, 'prod-102');
    expect(product.category, 'components');
    expect(product.price, 140000);
    expect(product.parts.single.name, 'Battery Module');
  });

  test('counts the requested Firestore order statuses', () {
    final counts = DashboardOrderCounts.fromStatuses([
      'placed',
      'placed',
      'out for delivery',
      'delivered',
      'selected',
      null,
    ]);

    expect(counts.total, 6);
    expect(counts.pending, 2);
    expect(counts.onRoute, 1);
    expect(counts.delivered, 1);
  });

  testWidgets('shows live customer and order counts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          dataSource: _FakeDashboardDataSource(),
          productsDataSource: _FakeProductsDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Orders'), findsOneWidget);
    expect(find.text('Registered Customers'), findsOneWidget);
    expect(find.text('Total Orders'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
  });

  testWidgets('shows Firestore products and their optional details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductsScreen(dataSource: _FakeProductsDataSource()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flagship Smartphone Unit'), findsOneWidget);
    expect(find.text('1 of 1 products'), findsOneWidget);
    expect(find.text('1 variant · 1 part'), findsOneWidget);

    await tester.tap(find.text('1 variant · 1 part'));
    await tester.pumpAndSettle();

    expect(find.text('Standard Unit'), findsOneWidget);
    expect(find.text('Battery Module'), findsOneWidget);
    expect(find.text('5000mAh Li-Po'), findsOneWidget);
  });
}
