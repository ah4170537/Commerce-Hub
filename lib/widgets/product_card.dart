import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/products_data_source.dart';

class ProductCard extends StatefulWidget {
  final StoreProduct product;
  final VoidCallback? onEdit;

  const ProductCard({super.key, required this.product, this.onEdit});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product.imageUrls.isEmpty ? null : product.imageUrls.first;
    final hasDetails = product.variants.isNotEmpty || product.parts.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFF243046),
                  child: imageUrl == null
                      ? _imagePlaceholder()
                      : Image.network(
                          imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _imagePlaceholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: widget.onEdit,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryAccentLight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.id} · ${product.category}'
                      '${product.subCategory.isEmpty ? '' : ' · ${product.subCategory}'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.price == null
                          ? 'Price unavailable'
                          : 'PKR ${_formatNumber(product.price!)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasDetails) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() {
                _detailsExpanded = !_detailsExpanded;
              }),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _detailsLabel(product),
                        style: const TextStyle(
                          color: AppColors.primaryAccentLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _detailsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryAccentLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_detailsExpanded) ...[
              const Divider(color: AppColors.cardBorder, height: 16),
              ...product.variants.map(
                (variant) => _buildDetailRow(
                  label: variant.name,
                  detail: variant.price == null
                      ? null
                      : 'PKR ${_formatNumber(variant.price!)}',
                ),
              ),
              ...product.parts.map(
                (part) => _buildDetailRow(
                  label: part.name,
                  subtitle: part.specs,
                  detail: part.price == null
                      ? null
                      : 'PKR ${_formatNumber(part.price!)}',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textSecondary,
        size: 32,
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    String? subtitle,
    String? detail,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (detail != null) ...[
            const SizedBox(width: 8),
            Text(
              detail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _detailsLabel(StoreProduct product) {
    final counts = <String>[
      if (product.variants.isNotEmpty)
        '${product.variants.length} ${product.variants.length == 1 ? 'variant' : 'variants'}',
      if (product.parts.isNotEmpty)
        '${product.parts.length} ${product.parts.length == 1 ? 'part' : 'parts'}',
    ];
    return counts.join(' · ');
  }

  String _formatNumber(num value) {
    final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final parts = text.split('.');
    final whole = parts.first;
    final grouped = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(whole[index]);
    }
    return parts.length == 1
        ? grouped.toString()
        : '${grouped.toString()}.${parts.last}';
  }
}
