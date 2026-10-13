import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class CategoriesRepository {
  Stream<List<String>> watchCategories();

  Future<List<String>> getCategories();

  Stream<List<String>> watchSubCategories();

  Future<List<String>> getSubCategories();

  Future<void> addCategory(String name);

  Future<void> addSubCategory(String name);

  Future<void> renameCategory({
    required String oldName,
    required String newName,
  });

  Future<void> renameSubCategory({
    required String oldName,
    required String newName,
  });

  Future<void> deleteCategory(String name);

  Future<void> deleteSubCategory(String name);
}

class FirestoreCategoriesRepository implements CategoriesRepository {
  final FirebaseFirestore _firestore;

  FirestoreCategoriesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<String>> watchCategories() {
    List<String>? savedCategories;
    List<String>? productCategories;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    categorySubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    productSubscription;

    late final StreamController<List<String>> controller;
    void emitCategories() {
      if (savedCategories == null || productCategories == null) return;
      final uniqueNames = <String, String>{};
      for (final name in [...savedCategories!, ...productCategories!]) {
        uniqueNames.putIfAbsent(name, () => name);
      }
      final names = uniqueNames.values.toList()..sort();
      controller.add(names);
    }

    controller = StreamController<List<String>>(
      onListen: () {
        categorySubscription = _firestore
            .collection('categories')
            .snapshots()
            .listen(
              (snapshot) {
                savedCategories = snapshot.docs
                    .map((document) => document.data()['name'])
                    .whereType<String>()
                    .map((name) => name.trim())
                    .where((name) => name.isNotEmpty)
                    .toList();
                emitCategories();
              },
              onError: controller.addError,
            );
        productSubscription = _firestore
            .collection('products')
            .snapshots()
            .listen(
              (snapshot) {
                productCategories = snapshot.docs
                    .map((document) => document.data()['category'])
                    .whereType<String>()
                    .map((name) => name.trim())
                    .where((name) => name.isNotEmpty)
                    .toList();
                emitCategories();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await categorySubscription?.cancel();
        await productSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<List<String>> getCategories() async {
    final snapshots = await Future.wait([
      _firestore.collection('categories').get(),
      _firestore.collection('products').get(),
    ]);
    final uniqueNames = <String, String>{};
    for (final name in [
      ...snapshots[0].docs
          .map((document) => document.data()['name'])
          .whereType<String>(),
      ...snapshots[1].docs
          .map((document) => document.data()['category'])
          .whereType<String>(),
    ]) {
      final normalizedName = name.trim();
      if (normalizedName.isNotEmpty) {
        uniqueNames.putIfAbsent(normalizedName, () => normalizedName);
      }
    }
    return uniqueNames.values.toList()..sort();
  }

  @override
  Stream<List<String>> watchSubCategories() {
    List<String>? savedSubCategories;
    List<String>? productSubCategories;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    subCategorySubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    productSubscription;

    late final StreamController<List<String>> controller;
    void emitSubCategories() {
      if (savedSubCategories == null || productSubCategories == null) return;
      controller.add(_sortedUniqueNames([
        ...savedSubCategories!,
        ...productSubCategories!,
      ]));
    }

    controller = StreamController<List<String>>(
      onListen: () {
        subCategorySubscription = _firestore
            .collection('subcategories')
            .snapshots()
            .listen(
              (snapshot) {
                savedSubCategories = snapshot.docs
                    .map((document) => document.data()['name'])
                    .whereType<String>()
                    .toList();
                emitSubCategories();
              },
              onError: controller.addError,
            );
        productSubscription = _firestore
            .collection('products')
            .snapshots()
            .listen(
              (snapshot) {
                productSubCategories = snapshot.docs
                    .map((document) => document.data()['subCategory'])
                    .whereType<String>()
                    .toList();
                emitSubCategories();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await subCategorySubscription?.cancel();
        await productSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<List<String>> getSubCategories() async {
    final snapshots = await Future.wait([
      _firestore.collection('subcategories').get(),
      _firestore.collection('products').get(),
    ]);
    return _sortedUniqueNames([
      ...snapshots[0].docs
          .map((document) => document.data()['name'])
          .whereType<String>(),
      ...snapshots[1].docs
          .map((document) => document.data()['subCategory'])
          .whereType<String>(),
    ]);
  }

  @override
  Future<void> addCategory(String name) async {
    final normalizedName = _validatedName(name);
    final categorySnapshot = await _firestore.collection('categories').get();
    if (categorySnapshot.docs.any(
      (document) =>
          _categoryName(document.data())?.toLowerCase() ==
          normalizedName.toLowerCase(),
    )) {
      throw StateError('A category named "$normalizedName" already exists.');
    }

    final productSnapshot = await _firestore
        .collection('products')
        .where('category', isEqualTo: normalizedName)
        .limit(1)
        .get();
    if (productSnapshot.docs.isNotEmpty) {
      throw StateError('A category named "$normalizedName" already exists.');
    }

    await _firestore.collection('categories').add({
      'name': normalizedName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addSubCategory(String name) async {
    final normalizedName = _validatedSubCategoryName(name);
    final savedSubCategories = await _firestore
        .collection('subcategories')
        .get();
    if (savedSubCategories.docs.any(
      (document) =>
          _categoryName(document.data())?.toLowerCase() ==
          normalizedName.toLowerCase(),
    )) {
      throw StateError(
        'A subcategory named "$normalizedName" already exists.',
      );
    }

    final productSnapshot = await _firestore
        .collection('products')
        .where('subCategory', isEqualTo: normalizedName)
        .limit(1)
        .get();
    if (productSnapshot.docs.isNotEmpty) {
      throw StateError(
        'A subcategory named "$normalizedName" already exists.',
      );
    }

    await _firestore.collection('subcategories').add({
      'name': normalizedName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> renameCategory({
    required String oldName,
    required String newName,
  }) async {
    final normalizedOldName = _validatedName(oldName);
    final normalizedNewName = _validatedName(newName);
    if (normalizedOldName == normalizedNewName) return;

    final categoryCollection = _firestore.collection('categories');
    final savedCategories = await categoryCollection.get();
    final duplicateCategory = savedCategories.docs.any((document) {
      final existingName = _categoryName(document.data());
      return existingName != null &&
          existingName.toLowerCase() == normalizedNewName.toLowerCase() &&
          existingName.toLowerCase() != normalizedOldName.toLowerCase();
    });
    if (duplicateCategory) {
      throw StateError('A category named "$normalizedNewName" already exists.');
    }

    final conflictingProducts = await _firestore
        .collection('products')
        .where('category', isEqualTo: normalizedNewName)
        .limit(1)
        .get();
    if (conflictingProducts.docs.any(
      (document) => document.data()['category'] != normalizedOldName,
    )) {
      throw StateError('A category named "$normalizedNewName" already exists.');
    }

    final products = await _firestore
        .collection('products')
        .where('category', isEqualTo: normalizedOldName)
        .get();
    for (var offset = 0; offset < products.docs.length; offset += 450) {
      final batch = _firestore.batch();
      for (final product in products.docs.skip(offset).take(450)) {
        batch.update(product.reference, {
          'category': normalizedNewName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    final matchingCategories = savedCategories.docs
        .where((document) => _categoryName(document.data()) == normalizedOldName)
        .toList();
    if (matchingCategories.isEmpty) {
      await categoryCollection.add({
        'name': normalizedNewName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    for (var offset = 0; offset < matchingCategories.length; offset += 450) {
      final batch = _firestore.batch();
      for (final category in matchingCategories.skip(offset).take(450)) {
        batch.update(category.reference, {
          'name': normalizedNewName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  @override
  Future<void> renameSubCategory({
    required String oldName,
    required String newName,
  }) async {
    final normalizedOldName = _validatedSubCategoryName(oldName);
    final normalizedNewName = _validatedSubCategoryName(newName);
    if (normalizedOldName == normalizedNewName) return;

    final subCategoryCollection = _firestore.collection('subcategories');
    final savedSubCategories = await subCategoryCollection.get();
    final duplicateSubCategory = savedSubCategories.docs.any((document) {
      final existingName = _categoryName(document.data());
      return existingName != null &&
          existingName.toLowerCase() == normalizedNewName.toLowerCase() &&
          existingName.toLowerCase() != normalizedOldName.toLowerCase();
    });
    if (duplicateSubCategory) {
      throw StateError(
        'A subcategory named "$normalizedNewName" already exists.',
      );
    }

    final conflictingProducts = await _firestore
        .collection('products')
        .where('subCategory', isEqualTo: normalizedNewName)
        .limit(1)
        .get();
    if (conflictingProducts.docs.any(
      (document) => document.data()['subCategory'] != normalizedOldName,
    )) {
      throw StateError(
        'A subcategory named "$normalizedNewName" already exists.',
      );
    }

    final products = await _firestore
        .collection('products')
        .where('subCategory', isEqualTo: normalizedOldName)
        .get();
    for (var offset = 0; offset < products.docs.length; offset += 450) {
      final batch = _firestore.batch();
      for (final product in products.docs.skip(offset).take(450)) {
        batch.update(product.reference, {
          'subCategory': normalizedNewName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    final matchingSubCategories = savedSubCategories.docs
        .where(
          (document) => _categoryName(document.data()) == normalizedOldName,
        )
        .toList();
    if (matchingSubCategories.isEmpty) {
      await subCategoryCollection.add({
        'name': normalizedNewName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    for (
      var offset = 0;
      offset < matchingSubCategories.length;
      offset += 450
    ) {
      final batch = _firestore.batch();
      for (final subCategory
          in matchingSubCategories.skip(offset).take(450)) {
        batch.update(subCategory.reference, {
          'name': normalizedNewName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteCategory(String name) async {
    final categoryName = _validatedName(name);
    final products = await _firestore
        .collection('products')
        .where('category', isEqualTo: categoryName)
        .get();

    for (var offset = 0; offset < products.docs.length; offset += 450) {
      final batch = _firestore.batch();
      for (final product in products.docs.skip(offset).take(450)) {
        batch.delete(product.reference);
      }
      await batch.commit();
    }

    final savedCategories = await _firestore.collection('categories').get();
    final matchingCategories = savedCategories.docs
        .where((document) => _categoryName(document.data()) == categoryName)
        .toList();
    for (var offset = 0; offset < matchingCategories.length; offset += 450) {
      final batch = _firestore.batch();
      for (final category in matchingCategories.skip(offset).take(450)) {
        batch.delete(category.reference);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteSubCategory(String name) async {
    final subCategoryName = _validatedSubCategoryName(name);
    final products = await _firestore
        .collection('products')
        .where('subCategory', isEqualTo: subCategoryName)
        .get();

    for (var offset = 0; offset < products.docs.length; offset += 450) {
      final batch = _firestore.batch();
      for (final product in products.docs.skip(offset).take(450)) {
        batch.update(product.reference, {
          'subCategory': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    final savedSubCategories = await _firestore
        .collection('subcategories')
        .get();
    final matchingSubCategories = savedSubCategories.docs
        .where(
          (document) => _categoryName(document.data()) == subCategoryName,
        )
        .toList();
    for (
      var offset = 0;
      offset < matchingSubCategories.length;
      offset += 450
    ) {
      final batch = _firestore.batch();
      for (final subCategory
          in matchingSubCategories.skip(offset).take(450)) {
        batch.delete(subCategory.reference);
      }
      await batch.commit();
    }
  }

  static List<String> _sortedUniqueNames(Iterable<Object?> names) {
    final uniqueNames = <String, String>{};
    for (final name in names.whereType<String>()) {
      final normalizedName = name.trim();
      if (normalizedName.isNotEmpty) {
        uniqueNames.putIfAbsent(normalizedName, () => normalizedName);
      }
    }
    return uniqueNames.values.toList()..sort();
  }

  static String? _categoryName(Map<String, dynamic> data) {
    final name = data['name'];
    return name is String && name.trim().isNotEmpty ? name.trim() : null;
  }

  static String _validatedName(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Category name cannot be empty.');
    }
    return normalizedName;
  }

  static String _validatedSubCategoryName(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Subcategory name cannot be empty.',
      );
    }
    return normalizedName;
  }
}
