// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:commerce_hub/screens/categories_screen.dart';
import 'package:commerce_hub/screens/dashboard_screen.dart';
import 'package:commerce_hub/screens/product_editor_screen.dart';
import 'package:commerce_hub/screens/products_screen.dart';
import 'package:commerce_hub/services/categories_repository.dart';
import 'package:commerce_hub/services/dashboard_data_source.dart';
import 'package:commerce_hub/services/product_editor_repository.dart';
import 'package:commerce_hub/services/products_data_source.dart';
import 'package:image_picker/image_picker.dart';

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

class _FakeCategoriesRepository implements CategoriesRepository {
  String? addedName;
  String? renamedFrom;
  String? renamedTo;
  String? deletedCategory;

  @override
  Stream<List<String>> watchCategories() =>
      Stream.value(['components', 'featured']);

  @override
  Future<List<String>> getCategories() async => ['components', 'featured'];

  @override
  Future<void> addCategory(String name) async {
    addedName = name;
  }

  @override
  Future<void> renameCategory({
    required String oldName,
    required String newName,
  }) async {
    renamedFrom = oldName;
    renamedTo = newName;
  }

  @override
  Future<void> deleteCategory(String name) async {
    deletedCategory = name;
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

class _FakeProductEditorRepository implements ProductEditorRepository {
  Map<String, dynamic>? savedFields;
  Map<String, dynamic>? createdFields;
  String? savedProductId;
  String? deletedProductId;

  @override
  Future<void> createProduct({
    required Map<String, dynamic> fields,
    required List<XFile> addedImages,
  }) async {
    createdFields = fields;
  }

  @override
  Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> fields,
    required List<String> retainedImageUrls,
    required List<XFile> addedImages,
  }) async {
    savedProductId = productId;
    savedFields = fields;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    deletedProductId = productId;
  }
}

void main() {
  test('uploads image bytes to ImgBB and returns the hosted URL', () async {
    final uploader = ImgBBImageUploader(
      apiKey: 'test-key',
      httpClient: MockClient((request) async {
        expect(request.url.host, 'api.imgbb.com');
        expect(request.url.queryParameters['key'], 'test-key');
        expect(request.bodyFields['image'], base64Encode([1, 2, 3]));
        expect(request.bodyFields['name'], 'product.jpg');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'url': 'https://i.ibb.co/product.jpg'},
          }),
          200,
        );
      }),
    );

    final url = await uploader.upload(
      'product.jpg',
      Uint8List.fromList([1, 2, 3]),
    );
    expect(url, 'https://i.ibb.co/product.jpg');
  });

  test('reads the ImgBB API key from dotenv', () async {
    await dotenv.load(
      isOptional: true,
      mergeWith: {'IMGBB_API_KEY': 'loaded-from-env'},
    );

    expect(ImgBBImageUploader().apiKey, 'loaded-from-env');
  });

  test(
    'requires an ImgBB API key only when image uploading is requested',
    () async {
      final uploader = ImgBBImageUploader(
        apiKey: '',
        httpClient: MockClient((request) async {
          fail('Should not make an HTTP request without an API key.');
        }),
      );

      await expectLater(
        uploader.upload('product.jpg', Uint8List.fromList([1])),
        throwsA(
          isA<ProductImageUploadException>().having(
            (error) => error.toString(),
            'message',
            contains('IMGBB_API_KEY'),
          ),
        ),
      );
    },
  );

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
          categoriesRepository: _FakeCategoriesRepository(),
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

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(
      find.text('Organize the categories used by your products'),
      findsOneWidget,
    );
    expect(find.text('components'), findsOneWidget);
  });

  testWidgets('shows Firestore products and their optional details', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductEditorRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductsScreen(
            dataSource: _FakeProductsDataSource(),
            editorRepository: repository,
            categoriesRepository: _FakeCategoriesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flagship Smartphone Unit'), findsOneWidget);
    expect(find.textContaining('prod-102'), findsNothing);
    expect(find.text('1 of 1 products'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('1 variant · 1 part'), findsOneWidget);

    await tester.tap(find.text('1 variant · 1 part'));
    await tester.pumpAndSettle();

    expect(find.text('Standard Unit'), findsOneWidget);
    expect(find.text('Battery Module'), findsOneWidget);
    expect(find.text('5000mAh Li-Po'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit product'));
    await tester.pumpAndSettle();

    expect(find.text('Edit product'), findsOneWidget);
    expect(find.text('prod-102'), findsNothing);
  });

  testWidgets('creates a product from the products page', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductEditorRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductsScreen(
            dataSource: _FakeProductsDataSource(),
            editorRepository: repository,
            categoriesRepository: _FakeCategoriesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    expect(find.text('New product'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'New headphones');
    await tester.enterText(find.byType(TextFormField).at(2), '4500');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('components').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();

    expect(repository.createdFields?['name'], 'New headphones');
    expect(repository.createdFields?['price'], 4500);
    expect(repository.createdFields?['category'], 'components');
  });

  testWidgets('adds and renames categories from the category page', (
    WidgetTester tester,
  ) async {
    final repository = _FakeCategoriesRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CategoriesScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Best Selling');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repository.addedName, 'Best Selling');

    await tester.tap(find.byTooltip('Edit featured'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Featured Picks');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repository.renamedFrom, 'featured');
    expect(repository.renamedTo, 'Featured Picks');

    await tester.tap(find.byTooltip('Delete featured'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Deleting "featured" will permanently delete the category and every product assigned to it. This cannot be undone.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete category and products'));
    await tester.pumpAndSettle();
    expect(repository.deletedCategory, 'featured');
  });

  testWidgets('deletes an individual product after confirmation', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductEditorRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductsScreen(
            dataSource: _FakeProductsDataSource(),
            editorRepository: repository,
            categoriesRepository: _FakeCategoriesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete product'));
    await tester.pumpAndSettle();
    expect(find.text('Delete product?'), findsOneWidget);
    await tester.tap(find.text('Delete product'));
    await tester.pumpAndSettle();
    expect(repository.deletedProductId, 'prod-102');
  });

  testWidgets('edits a product and saves the changed Firestore fields', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductEditorRepository();
    final product = StoreProduct.fromDocument('prod-001', {
      'id': 'prod-001',
      'name': 'Wireless Headphones',
      'description': 'Noise canceling headphones',
      'category': 'featured',
      'subCategory': 'headphones',
      'price': 3000,
      'variants': [
        {'name': 'Matte Black', 'price': 3000},
      ],
      'imageUrls': ['https://example.com/image.jpg'],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductEditorScreen(
            product: product,
            repository: repository,
            categoriesRepository: _FakeCategoriesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('components').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Updated headset');
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();

    expect(repository.savedProductId, 'prod-001');
    expect(repository.savedFields?['name'], 'Updated headset');
    expect(repository.savedFields?['category'], 'components');
    expect(repository.savedFields?['variants'], [
      {'name': 'Matte Black', 'price': 3000},
    ]);
  });

  testWidgets('keeps product image previews constrained while scrolling', (
    WidgetTester tester,
  ) async {
    final product = StoreProduct.fromDocument('prod-images', {
      'name': 'Image-heavy product',
      'category': 'components',
      'imageUrls': ['https://example.com/product-image.jpg'],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductEditorScreen(
            product: product,
            repository: _FakeProductEditorRepository(),
            categoriesRepository: _FakeCategoriesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageTile = find.byKey(
      const ValueKey('existing-0-https://example.com/product-image.jpg'),
    );
    await tester.scrollUntilVisible(
      imageTile,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.getSize(imageTile), const Size(92, 92));
    expect(find.text('Product images'), findsOneWidget);

    final pageScroll = find.byType(Scrollable).first;
    await tester.drag(pageScroll, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.drag(pageScroll, const Offset(0, 700));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(imageTile, 200, scrollable: pageScroll);
    expect(tester.getSize(imageTile), const Size(92, 92));
  });
}
