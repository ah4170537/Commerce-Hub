import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ActiveOrdersCard extends StatelessWidget {
  final VoidCallback? onViewAll;

  const ActiveOrdersCard({
    super.key,
    this.onViewAll,
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
                'Active orders',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
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
                  value: '12',
                  label: 'Preparing',
                ),
              ),
              Expanded(
                child: _buildStatusColumn(
                  value: '8',
                  label: 'On route',
                ),
              ),
              Expanded(
                child: _buildStatusColumn(
                  value: '36',
                  label: 'Delivered',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusColumn({
    required String value,
    required String label,
  }) {
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

