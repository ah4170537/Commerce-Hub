import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/alert_banner.dart';
import '../widgets/kpi_card.dart';
import '../widgets/order_fulfillment_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/active_orders_card.dart';
import '../widgets/custom_bottom_nav.dart';
import 'products_screen.dart';
import 'broadcast_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentTab,
          children: [
            // Tab 0: Dashboard Overview
            _buildDashboardView(),

            // Tab 1: Products / Inventory
            const ProductsScreen(),

            // Tab 2: Riders (Placeholder for next screen)
            _buildPlaceholderView(
              title: 'Riders Control',
              subtitle: 'Manage rider fleet, active routes & documents',
              icon: Icons.two_wheeler_rounded,
            ),

            // Tab 3: Customers (Placeholder for next screen)
            _buildPlaceholderView(
              title: 'Customer Management',
              subtitle: 'Manage registered users, order histories & disputes',
              icon: Icons.people_outline_rounded,
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentTab,
        onTabSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
      ),
    );
  }

  /// Dashboard Overview Tab Content
  Widget _buildDashboardView() {
    return Column(
      children: [
        // Top App Bar
        _buildAppBar(),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Title & Date
                const Text(
                  'Overview',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Monday, October 12 · Today's operations",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),

                // Alert Banner
                AlertBanner(
                  text: '28 new orders are waiting for review',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening pending orders for review...'),
                        backgroundColor: AppColors.cardSurface,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2x2 KPI Cards
                Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'New Orders',
                        value: '28',
                        subtitle: 'Pending acceptance',
                        subtitleColor: AppColors.warning,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiCard(
                        icon: Icons.two_wheeler_rounded,
                        title: 'Active Riders',
                        value: '14',
                        subtitle: 'Total · 8 on route',
                        subtitleColor: AppColors.success,
                        onTap: () {
                          setState(() {
                            _currentTab = 2; // Switch to Riders tab
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        icon: Icons.people_outline_rounded,
                        title: 'Registered Customers',
                        value: '1,240',
                        subtitle: 'Customer accounts',
                        subtitleColor: AppColors.primaryAccentLight,
                        onTap: () {
                          setState(() {
                            _currentTab = 3; // Switch to Customers tab
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Current Sales Revenue',
                        value: r'$1,450',
                        subtitle: "Today's sales",
                        subtitleColor: AppColors.primaryAccentLight,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order Fulfillment Card
                const OrderFulfillmentCard(),
                const SizedBox(height: 20),

                // Quick Actions
                QuickActions(
                  onAddProduct: () {
                    setState(() {
                      _currentTab = 1; // Switch to Products tab
                    });
                  },
                  onDispatch: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dispatch action triggered'),
                        backgroundColor: AppColors.cardSurface,
                      ),
                    );
                  },
                  onBroadcast: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BroadcastScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Active Orders Card
                ActiveOrdersCard(
                  onViewAll: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigating to all active orders...'),
                        backgroundColor: AppColors.cardSurface,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Top Hub App Bar for Dashboard
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // User Avatar Circle "AL"
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryAccent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'AL',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Hub Title & Live Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Admin Operations Hub',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Main store · Live sync',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notification Bell with Badge Dot
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications tapped'),
                  backgroundColor: AppColors.cardSurface,
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
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

  /// Placeholder for tabs under development
  Widget _buildPlaceholderView({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBorder.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primaryAccentLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
