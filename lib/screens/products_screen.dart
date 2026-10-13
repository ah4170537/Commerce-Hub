import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/categories_repository.dart';
import '../services/product_editor_repository.dart';
import '../services/products_data_source.dart';
import '../widgets/product_card.dart';
import 'product_editor_screen.dart';

class ProductsScreen extends StatefulWidget {
  final ProductsDataSource? dataSource;
  final ProductEditorRepository? editorRepository;
  final CategoriesRepository? categoriesRepository;

  const ProductsScreen({
    super.key,
    this.dataSource,
    this.editorRepository,
    this.categoriesRepository,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ProductsDataSource _dataSource;
  late final Stream<List<StoreProduct>> _productsStream;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dataSource = widget.dataSource ?? FirestoreProductsDataSource();
    _productsStream = _dataSource.watchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<List<StoreProduct>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildMessage(
                  'Could not load products.\n${snapshot.error}',
                  icon: Icons.error_outline_rounded,
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                );
              }

              final products = snapshot.data!;
              final categories =
                  products
                      .map((product) => product.category)
                      .where((category) => category.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              final selectedCategory = categories.contains(_selectedCategory)
                  ? _selectedCategory
                  : null;
              final query = _searchQuery.trim().toLowerCase();
              final filteredProducts = products.where((product) {
                final matchesCategory =
                    selectedCategory == null ||
                    product.category == selectedCategory;
                final searchableText = [
                  product.id,
                  product.name,
                  product.category,
                  product.subCategory,
                  ...product.variants.map((variant) => variant.name),
                  ...product.parts.expand(
                    (part) => [part.name, part.specs ?? ''],
                  ),
                ].join(' ').toLowerCase();

                return matchesCategory &&
                    (query.isEmpty || searchableText.contains(query));
              }).toList();

              return _buildProductList(
                products: filteredProducts,
                totalCount: products.length,
                categories: categories,
                selectedCategory: selectedCategory,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Live product catalog',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.sync_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: 6),
          const Text(
            'Live',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList({
    required List<StoreProduct> products,
    required int totalCount,
    required List<String> categories,
    required String? selectedCategory,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildSearchBar(),
        const SizedBox(height: 14),
        _buildCategoryFilters(categories, selectedCategory),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Product catalog',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${products.length} of $totalCount products',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (products.isEmpty)
          _buildMessage(
            totalCount == 0
                ? 'No products found in the products collection.'
                : 'No products match this search or category.',
            icon: Icons.inventory_2_outlined,
          )
        else
          ...products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductCard(
                product: product,
                onEdit: () => _editProduct(product),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editProduct(StoreProduct product) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditorScreen(
          product: product,
          repository: widget.editorRepository,
          categoriesRepository: widget.categoriesRepository,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
              ),
              cursorColor: AppColors.primaryAccent,
              decoration: const InputDecoration(
                hintText: 'Search name, ID, category or parts',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              tooltip: 'Clear search',
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(
    List<String> categories,
    String? selectedCategory,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _categoryChip(
            label: 'All',
            selected: selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ...categories.map(
            (category) => _categoryChip(
              label: category,
              selected: selectedCategory == category,
              onTap: () => setState(() => _selectedCategory = category),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: selected
            ? AppColors.primaryAccent
            : AppColors.cardSurface,
        side: BorderSide(
          color: selected
              ? AppColors.primaryAccent
              : AppColors.cardBorder.withValues(alpha: 0.5),
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }

  Widget _buildMessage(String message, {required IconData icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
