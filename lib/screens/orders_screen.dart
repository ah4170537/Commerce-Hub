import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/orders_data_source.dart';

class OrdersScreen extends StatefulWidget {
  final OrdersDataSource? dataSource;
  final OrderStatusFilter initialFilter;

  const OrdersScreen({
    super.key,
    this.dataSource,
    this.initialFilter = OrderStatusFilter.all,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Stream<List<StoreOrder>> _ordersStream;
  late OrderStatusFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _ordersStream = (widget.dataSource ?? FirestoreOrdersDataSource())
        .watchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            Expanded(
              child: StreamBuilder<List<StoreOrder>>(
                stream: _ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildMessage(
                      'Could not load orders.\n${snapshot.error}',
                      Icons.error_outline_rounded,
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                      ),
                    );
                  }

                  final orders = snapshot.data!
                      .where((order) => order.matchesStatus(_selectedFilter))
                      .toList();
                  if (orders.isEmpty) {
                    return _buildMessage(
                      _selectedFilter == OrderStatusFilter.all
                          ? 'No orders yet.'
                          : 'No ${_selectedFilter.label.toLowerCase()} orders.',
                      Icons.receipt_long_outlined,
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _OrderCard(order: orders[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: OrderStatusFilter.values.map((filter) {
          final selected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: AppColors.primaryAccent,
              backgroundColor: AppColors.cardSurface,
              side: BorderSide(
                color: selected
                    ? AppColors.primaryAccent
                    : AppColors.cardBorder,
              ),
              labelStyle: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessage(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final StoreOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final itemsTotal = order.items.fold<num>(
      0,
      (total, item) => total + (item.lineTotal ?? 0),
    );
    final orderTotal = order.total ?? (order.items.isEmpty ? null : itemsTotal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (order.customerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        order.customerName!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (order.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt!),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          if (order.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                'Product details are not available for this order.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            )
          else
            ...order.items.map(_buildItem),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${order.items.length} ${order.items.length == 1 ? 'product' : 'products'}'
                ' · ${order.items.fold<int>(0, (total, item) => total + item.quantity)} items',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Text(
                'Total ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                orderTotal == null
                    ? 'PKR —'
                    : 'PKR ${_formatNumber(orderTotal)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${item.unitPrice == null ? 'PKR —' : 'PKR ${_formatNumber(item.unitPrice!)}'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                ...item.parts.map(_buildPart),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.lineTotal == null
                ? 'PKR —'
                : 'PKR ${_formatNumber(item.lineTotal!)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPart(OrderItemPart part) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: AppColors.primaryAccentLight, fontSize: 11),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (part.specs != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    part.specs!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (part.price != null) ...[
            const SizedBox(width: 8),
            Text(
              'PKR ${_formatNumber(part.price!)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'placed':
    case 'pending':
      return AppColors.warning;
    case 'out for delivery':
    case 'on route':
      return AppColors.primaryAccentLight;
    case 'delivered':
      return AppColors.success;
    default:
      return AppColors.textSecondary;
  }
}

String _formatDate(DateTime date) {
  final localDate = date.toLocal();
  final month = localDate.month.toString().padLeft(2, '0');
  final day = localDate.day.toString().padLeft(2, '0');
  return '$month/$day/${localDate.year}';
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
