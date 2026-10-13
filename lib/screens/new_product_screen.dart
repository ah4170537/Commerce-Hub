import 'package:flutter/material.dart';

import '../services/categories_repository.dart';
import '../services/product_editor_repository.dart';
import '../services/products_data_source.dart';
import 'product_editor_screen.dart';

class NewProductScreen extends StatelessWidget {
  final ProductEditorRepository? repository;
  final CategoriesRepository? categoriesRepository;

  const NewProductScreen({
    super.key,
    this.repository,
    this.categoriesRepository,
  });

  @override
  Widget build(BuildContext context) {
    return ProductEditorScreen(
      product: const StoreProduct(
        id: '',
        name: '',
        description: null,
        category: '',
        subCategory: '',
        price: null,
        imageUrls: [],
        variants: [],
        parts: [],
      ),
      isCreating: true,
      repository: repository,
      categoriesRepository: categoriesRepository,
    );
  }
}
