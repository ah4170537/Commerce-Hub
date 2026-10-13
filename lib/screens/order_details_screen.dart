import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/orders_data_source.dart';

class OrderDetailsScreen extends StatefulWidget {
  final StoreOrder order;
  final OrdersDataSource dataSource;
  final RiderDetailsDataSource? riderDetailsDataSource;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.dataSource,
    this.riderDetailsDataSource,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isCancelling = false;
  late final Future<RiderDetails?>? _riderDetails;

  @override
  void initState() {
    super.initState();
    final riderId = widget.order.riderId;
    _riderDetails = riderId == null
        ? null
        : (widget.riderDetailsDataSource ??
                  FirestoreRiderDetailsDataSource())
              .getRiderDetails(riderId);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Order details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _DetailsCard(
            title: 'Order #${order.id}',
            children: [
              _DetailRow(label: 'Status', value: order.status),
              if (order.createdAt != null)
                _DetailRow(
                  label: 'Ordered on',
                  value: _formatDate(order.createdAt!),
                ),
              _DetailRow(
                label: 'Total',
                value: order.total == null
                    ? 'PKR —'
                    : 'PKR ${_formatNumber(order.total!)}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailsCard(
            title: 'Customer',
            children: [
              _DetailRow(label: 'Name', value: order.customerName),
              _DetailRow(label: 'Email', value: order.customerEmail),
              _DetailRow(label: 'Phone', value: order.customerPhone),
            ],
          ),
          const SizedBox(height: 12),
          _DetailsCard(
            title: 'Delivery address',
            children: [
              _DetailRow(label: 'Address', value: order.deliveryAddress),
            ],
          ),
          if (order.matchesStatus(OrderStatusFilter.onRoute) ||
              order.matchesStatus(OrderStatusFilter.delivered)) ...[
            const SizedBox(height: 12),
            _buildRiderDetails(order.riderId),
          ],
          const SizedBox(height: 12),
          _DetailsCard(
            title: 'Items',
            children: order.items.isEmpty
                ? const [
                    Text(
                      'Product details are not available for this order.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ]
                : order.items.map(_buildOrderItem).toList(),
          ),
          if (order.isPending) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isCancelling ? null : _confirmCancellation,
                icon: _isCancelling
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(_isCancelling ? 'Cancelling…' : 'Cancel order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiderDetails(String? riderId) {
    if (riderId == null) {
      return const _DetailsCard(
        title: 'Rider',
        children: [
          Text(
            'No rider details are saved on this order, so an assigned rider cannot be identified.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      );
    }

    return FutureBuilder<RiderDetails?>(
      future: _riderDetails,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _DetailsCard(
            title: 'Rider',
            children: [
              Text(
                'Could not load rider details for this order.',
                style: TextStyle(
                  color: AppColors.warning,
                  height: 1.4,
                ),
              ),
            ],
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DetailsCard(
            title: 'Rider',
            children: [
              Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                ),
              ),
            ],
          );
        }

        final rider = snapshot.data;
        if (rider == null) {
          return const _DetailsCard(
            title: 'Rider',
            children: [
              Text(
                'No matching rider details were found for this order.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          );
        }

        return _DetailsCard(
          title: 'Rider',
          children: [
            _DetailRow(label: 'Name', value: rider.fullName),
            _DetailRow(label: 'Phone', value: rider.phone),
            _DetailRow(label: 'Secondary phone', value: rider.secondaryPhone),
            _DetailRow(label: 'Email', value: rider.email),
            _DetailRow(label: 'Bike model', value: rider.bikeModel),
            _DetailRow(label: 'Bike number', value: rider.bikeNumber),
            _DetailRow(label: 'City', value: rider.city),
          ],
        );
      },
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${item.quantity} × ${item.name}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                item.lineTotal == null
                    ? 'PKR —'
                    : 'PKR ${_formatNumber(item.lineTotal!)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.unitPrice == null
                ? 'Unit price: PKR —'
                : 'Unit price: PKR ${_formatNumber(item.unitPrice!)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (item.parts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...item.parts.map((part) {
              return Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${part.quantity} × ${part.name}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (part.specs != null && part.specs!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        part.specs!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (part.price != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Price: PKR ${_formatNumber(part.price!)}',
                        style: const TextStyle(
                          color: AppColors.primaryAccentLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancellation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Cancel this order?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel order',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await widget.dataSource.cancelOrder(widget.order);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not cancel order: $error'),
          backgroundColor: AppColors.cardSurface,
        ),
      );
    }
  }
}

class _DetailsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
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
