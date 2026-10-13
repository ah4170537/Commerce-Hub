import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class ActiveOrdersCard extends StatelessWidget {
  final VoidCallback? onViewAll;
  final bool isLoading;
  final int? pendingCount;
  final int? onRouteCount;
  final int? deliveredCount;

  const ActiveOrdersCard({
    super.key,
    this.onViewAll,
    this.isLoading = false,
    required this.pendingCount,
    required this.onRouteCount,
    required this.deliveredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order status',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: isLoading ? null : onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryAccentLight,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Loading...',
                              style: TextStyle(
                                color: AppColors.primaryAccentLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'View all',
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
          const SizedBox(height: 18),

          // 3 Stats in a row
          Row(
            children: [
              Expanded(
                child: _buildStatusColumn(
                  value: _formatCount(pendingCount),
                  label: 'Pending',
                ),
              ),
              Expanded(
                child: _buildStatusColumn(
                  value: _formatCount(onRouteCount),
                  label: 'On route',
                ),
              ),
              Expanded(
                child: _buildStatusColumn(
                  value: _formatCount(deliveredCount),
                  label: 'Delivered',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int? count) => count?.toString() ?? '—';

  Widget _buildStatusColumn({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
