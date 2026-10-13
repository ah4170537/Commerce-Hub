import 'package:cloud_firestore/cloud_firestore.dart';

class ProductVariant {
  final String name;
  final num? price;

  const ProductVariant({required this.name, this.price});
}

class ProductPart {
  final String name;
  final String? specs;
  final num? price;

  const ProductPart({required this.name, this.specs, this.price});
}

class StoreProduct {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String subCategory;
  final num? price;
  final List<String> imageUrls;
  final List<ProductVariant> variants;
  final List<ProductPart> parts;

  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.price,
    required this.imageUrls,
    required this.variants,
    required this.parts,
  });

  factory StoreProduct.fromDocument(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final variants = data['variants'];
    final parts = data['parts'];
    final imageUrls = data['imageUrls'];

    return StoreProduct(
      id: _stringValue(data['id']) ?? documentId,
      name: _stringValue(data['name']) ?? 'Unnamed product',
      description: _stringValue(data['description']),
      category: _stringValue(data['category']) ?? 'Uncategorized',
      subCategory: _stringValue(data['subCategory']) ?? '',
      price: _numberValue(data['price']),
      imageUrls: imageUrls is List
          ? imageUrls.whereType<String>().toList()
          : const [],
      variants: variants is List
          ? variants
                .whereType<Map>()
                .map((variant) {
                  final values = Map<String, dynamic>.from(variant);
                  return ProductVariant(
                    name:
                        _stringValue(values['name']) ??
                        'Variant ${variants.indexOf(variant) + 1}',
                    price: _numberValue(values['price']),
                  );
                })
                .toList()
          : const [],
      parts: parts is List
          ? parts
                .whereType<Map>()
                .map((part) {
                  final values = Map<String, dynamic>.from(part);
                  return ProductPart(
                    name: _stringValue(values['partName']) ?? 'Unnamed part',
                    specs: _stringValue(values['specs']),
                    price: _numberValue(values['price']),
                  );
                })
                .toList()
          : const [],
    );
  }

  static String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static num? _numberValue(Object? value) {
    if (value is num) return value;
    return null;
  }
}

abstract interface class ProductsDataSource {
  Stream<List<StoreProduct>> watchProducts();
}

class FirestoreProductsDataSource implements ProductsDataSource {
  final FirebaseFirestore _firestore;

  FirestoreProductsDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<StoreProduct>> watchProducts() {
    return _firestore.collection('products').snapshots().map(
      (snapshot) => snapshot.docs
          .map((document) => StoreProduct.fromDocument(
                document.id,
                document.data(),
              ))
          .toList(),
    );
  }
}
