import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/categories_repository.dart';
import '../services/dashboard_data_source.dart';
import '../services/products_data_source.dart';
import '../widgets/alert_banner.dart';
import '../widgets/kpi_card.dart';
import '../widgets/order_fulfillment_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/active_orders_card.dart';
import '../widgets/custom_bottom_nav.dart';
import 'products_screen.dart';
import 'broadcast_screen.dart';
import 'categories_screen.dart';

class DashboardScreen extends StatefulWidget {
  final DashboardDataSource? dataSource;
  final ProductsDataSource? productsDataSource;
  final CategoriesRepository? categoriesRepository;

  const DashboardScreen({
    super.key,
    this.dataSource,
    this.productsDataSource,
    this.categoriesRepository,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;
  final Set<int> _visitedTabs = {0};
  int? _customerCount;
  int? _totalOrdersCount;
  int? _pendingOrdersCount;
  int? _onRouteOrdersCount;
  int? _deliveredOrdersCount;
  late final CategoriesRepository _categoriesRepository;
  Object? _usersError;
  Object? _ordersError;
  StreamSubscription<int>? _usersSubscription;
  StreamSubscription<DashboardOrderCounts>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _categoriesRepository =
        widget.categoriesRepository ?? FirestoreCategoriesRepository();
    final dataSource = widget.dataSource ?? FirestoreDashboardDataSource();

    _usersSubscription = dataSource.watchCustomerCount().listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _customerCount = snapshot;
          _usersError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _usersError = error);
      },
    );

    _ordersSubscription = dataSource.watchOrderCounts().listen(
      (counts) {
        if (!mounted) return;
        setState(() {
          _totalOrdersCount = counts.total;
          _pendingOrdersCount = counts.pending;
          _onRouteOrdersCount = counts.onRoute;
          _deliveredOrdersCount = counts.delivered;
          _ordersError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _ordersError = error);
      },
    );
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }

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
            if (_visitedTabs.contains(1))
              ProductsScreen(
                dataSource: widget.productsDataSource,
                categoriesRepository: _categoriesRepository,
              )
            else
              const SizedBox.shrink(),

            // Tab 2: Product categories
            if (_visitedTabs.contains(2))
              CategoriesScreen(repository: _categoriesRepository)
            else
              const SizedBox.shrink(),

            // Tab 3: Riders (Placeholder for next screen)
            if (_visitedTabs.contains(3))
              _buildPlaceholderView(
              title: 'Riders Control',
              subtitle: 'Manage rider fleet, active routes & documents',
              icon: Icons.two_wheeler_rounded,
              )
            else
              const SizedBox.shrink(),

            // Tab 4: Customers (Placeholder for next screen)
            if (_visitedTabs.contains(4))
              _buildPlaceholderView(
              title: 'Customer Management',
              subtitle: 'Manage registered users, order histories & disputes',
              icon: Icons.people_outline_rounded,
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentTab,
        onTabSelected: _selectTab,
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

                _buildDashboardDataStatus(),
                const SizedBox(height: 16),

                // Dashboard totals
                Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'New Orders',
                        value: _formatCount(_pendingOrdersCount),
                        subtitle: 'Pending · not selected',
                        subtitleColor: AppColors.warning,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiCard(
                        icon: Icons.people_outline_rounded,
                        title: 'Registered Customers',
                        value: _formatCount(_customerCount),
                        subtitle: 'Customer accounts',
                        subtitleColor: AppColors.primaryAccentLight,
                        onTap: () {
                          _selectTab(4);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                KpiCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Total Orders',
                  value: _formatCount(_totalOrdersCount),
                  subtitle: 'All order statuses',
                  subtitleColor: AppColors.primaryAccentLight,
                ),
                const SizedBox(height: 16),

                // Order Fulfillment Card
                const OrderFulfillmentCard(),
                const SizedBox(height: 20),

                // Quick Actions
                QuickActions(
                  onAddProduct: () {
                    _selectTab(1);
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
                  pendingCount: _pendingOrdersCount,
                  onRouteCount: _onRouteOrdersCount,
                  deliveredCount: _deliveredOrdersCount,
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

  String _formatCount(int? count) => count?.toString() ?? '—';

  void _selectTab(int index) {
    setState(() {
      _currentTab = index;
      _visitedTabs.add(index);
    });
  }

  Widget _buildDashboardDataStatus() {
    final errors = [
      if (_usersError != null) 'Users: $_usersError',
      if (_ordersError != null) 'Orders: $_ordersError',
    ];

    if (errors.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: Text(
          'Could not load live dashboard data.\n${errors.join('\n')}',
          style: const TextStyle(color: AppColors.warning, fontSize: 12),
        ),
      );
    }

    final pendingCount = _pendingOrdersCount;
    if (_customerCount == null ||
        _totalOrdersCount == null ||
        pendingCount == null) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    return AlertBanner(
      text:
          '$pendingCount new ${pendingCount == 1 ? 'order is' : 'orders are'} waiting for review',
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening pending orders for review...'),
            backgroundColor: AppColors.cardSurface,
          ),
        );
      },
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
              child: Icon(icon, size: 48, color: AppColors.primaryAccentLight),
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
