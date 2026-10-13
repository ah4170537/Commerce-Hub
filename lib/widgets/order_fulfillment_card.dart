import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class OrderFulfillmentCard extends StatelessWidget {
  const OrderFulfillmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Data representing the 4 weeks in the chart
    // Target height is normalized (e.g. 70), fulfilled varies
    final weeklyData = [
      {'label': 'Week 1', 'target': 70.0, 'fulfilled': 64.0},
      {'label': 'Week 2', 'target': 70.0, 'fulfilled': 88.0},
      {'label': 'Week 3', 'target': 70.0, 'fulfilled': 54.0},
      {'label': 'Week 4', 'target': 70.0, 'fulfilled': 28.0},
    ];

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
          // Header: Title & Month Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Order fulfillment',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: const [
                      Text(
                        'October',
                        style: TextStyle(
                          color: AppColors.primaryAccentLight,
                          fontSize: 13,
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
          ),
          const SizedBox(height: 12),

          // Percentage & On Track badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '78%',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'On track',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Subtitle
          const Text(
            '468 of 600 monthly target',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),

          // Chart Area
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                // Subtle horizontal baseline divider line
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Container(
                    height: 1,
                    color: AppColors.cardBorder.withValues(alpha: 0.4),
                  ),
                ),

                // Bar columns
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weeklyData.map((data) {
                    final targetH = data['target'] as double;
                    final fulfilledH = data['fulfilled'] as double;
                    final label = data['label'] as String;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bars container
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Target Bar (Muted Dark Slate)
                            Container(
                              width: 14,
                              height: targetH,
                              decoration: BoxDecoration(
                                color: AppColors.chartTarget,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Fulfilled Bar (Indigo Accent)
                            Container(
                              width: 14,
                              height: fulfilledH,
                              decoration: BoxDecoration(
                                color: AppColors.chartFulfilled,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Week label
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 18,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Fulfilled indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.chartFulfilled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Fulfilled',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              // Target indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.chartTarget,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Target · 150 / week',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

