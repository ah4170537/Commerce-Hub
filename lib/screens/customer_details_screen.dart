import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/customers_data_source.dart';
import '../services/orders_data_source.dart';
import 'orders_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final StoreCustomer customer;
  final OrdersDataSource? ordersDataSource;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
    this.ordersDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Customer details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildActions(context),
          const SizedBox(height: 20),
          _buildInformationCard(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildAvatar(customer, 88),
          const SizedBox(height: 14),
          Text(
            customer.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(StoreCustomer customer, double size) {
    final imageUrl = customer.imageUrl;
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryAccentMuted,
      child: Text(
        _initials(customer.name),
        style: TextStyle(
          color: AppColors.primaryAccentLight,
          fontSize: size / 3,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    if (imageUrl == null) return fallback;

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.block_outlined),
            label: const Text('Block customer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => OrdersScreen(
                    dataSource: ordersDataSource,
                    customerId: customer.id,
                    customerName: customer.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text("User's orders"),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInformationCard() {
    final entries = customer.details.entries
        .where((entry) => !_isHiddenField(entry.key))
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All customer information',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'No additional customer information is available.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...entries.map((entry) => _buildDataField(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildDataField(String key, Object? value, {int depth = 0}) {
    if (_isHiddenField(key)) return const SizedBox.shrink();

    final label = _formatLabel(key);
    final entries = _mapEntries(value);
    final items = value is List ? value : null;
    final indentation = depth == 0 ? 0.0 : 12.0;

    if (entries != null) {
      return Padding(
        padding: EdgeInsets.only(left: indentation, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Not provided',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...entries.entries.map(
                (entry) =>
                    _buildDataField(entry.key, entry.value, depth: depth + 1),
              ),
            if (depth == 0) const Divider(color: AppColors.cardBorder),
          ],
        ),
      );
    }

    if (items != null) {
      return Padding(
        padding: EdgeInsets.only(left: indentation, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (items.isEmpty)
              const Text(
                'Not provided',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...items.asMap().entries.map(
                (entry) => _buildDataField(
                  'Item ${entry.key + 1}',
                  entry.value,
                  depth: depth + 1,
                ),
              ),
            if (depth == 0) const Divider(color: AppColors.cardBorder),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: indentation, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            _formatValue(value),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          if (depth == 0) const Divider(color: AppColors.cardBorder),
        ],
      ),
    );
  }

  Map<String, dynamic>? _mapEntries(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  bool _isHiddenField(String key) {
    final normalizedKey = key.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return const {
      'id',
      'uid',
      'userid',
      'latitude',
      'longitude',
      'profileimage',
      'profileimageurl',
      'profileurl',
      'image',
      'imageurl',
      'photourl',
      'avatar',
      'avatarurl',
      'fcmtoken',
      'fcmtokens',
      'isblocked',
      'blockedat',
      'blockedby',
    }.contains(normalizedKey);
  }

  String _formatValue(Object? value) {
    if (value == null) return 'Not provided';
    if (value is Timestamp) return _formatDate(value.toDate());
    if (value is DateTime) return _formatDate(value);
    if (value is String && value.trim().isEmpty) return 'Not provided';
    return value.toString();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  String _formatLabel(String value) {
    final words = value
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'));
    return words
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.cardSurface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
  );
}
