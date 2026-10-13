import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Low stock, 2: Unavailable
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Header
        _buildHeader(),

        // Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 14),

                // Filter Chips
                _buildFilterChips(),
                const SizedBox(height: 14),

                // Warning / Restock Alert Banner
                _buildRestockBanner(),
                const SizedBox(height: 18),

                // Product Catalog Header
                _buildCatalogHeader(),
                const SizedBox(height: 14),

                // Product 1: Organic bananas
                ProductCard(
                  title: 'Organic bananas',
                  skuAndCategory: 'PRD-1042 · Fresh produce',
                  price: r'$2.40',
                  stockBadgeText: '84 in stock',
                  stockStatus: ProductStockStatus.inStock,
                  imageUrl:
                      'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=200&q=80',
                  onEditPrice: () => _showActionSnackbar('Edit price: Organic bananas'),
                  onUpdateStock: () => _showActionSnackbar('Update stock: Organic bananas'),
                  onMoreOptions: () => _showActionSnackbar('Options: Organic bananas'),
                ),
                const SizedBox(height: 12),

                // Product 2: Whole milk · 1L
                ProductCard(
                  title: 'Whole milk · 1L',
                  skuAndCategory: 'PRD-2088 · Dairy & eggs',
                  price: r'$3.25',
                  stockBadgeText: '6 left - Low stock',
                  stockStatus: ProductStockStatus.lowStock,
                  imageUrl:
                      'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=200&q=80',
                  onEditPrice: () => _showActionSnackbar('Edit price: Whole milk · 1L'),
                  onUpdateStock: () => _showActionSnackbar('Update stock: Whole milk · 1L'),
                  onMoreOptions: () => _showActionSnackbar('Options: Whole milk · 1L'),
                ),
                const SizedBox(height: 12),

                // Product 3: Sourdough loaf
                ProductCard(
                  title: 'Sourdough loaf',
                  skuAndCategory: 'PRD-3021 · Bakery',
                  price: r'$5.80',
                  stockBadgeText: 'Out of stock',
                  stockStatus: ProductStockStatus.outOfStock,
                  imageUrl:
                      'https://images.unsplash.com/photo-1589367920969-ab8e050bbb04?w=200&q=80',
                  onEditPrice: () => _showActionSnackbar('Edit price: Sourdough loaf'),
                  onUpdateStock: () => _showActionSnackbar('Update stock: Sourdough loaf'),
                  onMoreOptions: () => _showActionSnackbar('Options: Sourdough loaf'),
                ),
                const SizedBox(height: 18),

                // Category Control Card
                _buildCategoryControl(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
                  '124 products across 8 categories',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // + Add button
          InkWell(
            onTap: () => _showActionSnackbar('Add new product modal opened'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.5),
        ),
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
              ),
              cursorColor: AppColors.primaryAccent,
              decoration: const InputDecoration(
                hintText: 'Search name or product SKU',
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
          InkWell(
            onTap: () => _showActionSnackbar('Search filters opened'),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All products 124', 'type': 'all'},
      {'label': 'Low stock 9', 'type': 'low'},
      {'label': 'Unavailable 4', 'type': 'unavailable'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          final item = filters[index];

          Color bg;
          Color textColor;

          if (index == 0) {
            bg = isSelected ? AppColors.primaryAccent : AppColors.cardSurface;
            textColor = isSelected ? Colors.white : AppColors.textSecondary;
          } else if (index == 1) {
            bg = AppColors.warning;
            textColor = const Color(0xFF0F172A);
          } else {
            bg = AppColors.cardSurface;
            textColor = AppColors.textSecondary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected && index != 1
                        ? AppColors.primaryAccent
                        : AppColors.cardBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRestockBanner() {
    return InkWell(
      onTap: () => _showActionSnackbar('Opening 9 restocking items'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '9 products need restocking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        InkWell(
          onTap: () => _showActionSnackbar('Category dropdown selected'),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: const [
                Text(
                  'Category: All',
                  style: TextStyle(
                    color: AppColors.primaryAccentLight,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryAccentLight,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryControl() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category control',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => _showActionSnackbar('Manage categories clicked'),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Manage',
                    style: TextStyle(
                      color: AppColors.primaryAccentLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _showActionSnackbar('Fresh produce category selected'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cardBorder.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Fresh produce',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '32 products · Visible in customer app',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.cardSurface,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

