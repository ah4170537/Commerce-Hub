import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/customers_data_source.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  final CustomersDataSource? dataSource;

  const CustomersScreen({super.key, this.dataSource});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<StoreCustomer>> _customersStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _customersStream = (widget.dataSource ?? FirestoreCustomersDataSource())
        .watchCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<List<StoreCustomer>>(
            stream: _customersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildMessage(
                  'Could not load customers.\n${snapshot.error}',
                  icon: Icons.error_outline_rounded,
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                );
              }

              final customers = snapshot.data!
                  .where((customer) => customer.name.trim().isNotEmpty)
                  .toList();
              final query = _searchQuery.trim().toLowerCase();
              final filteredCustomers = customers.where((customer) {
                if (query.isEmpty) return true;
                return [
                  customer.name,
                  customer.email ?? '',
                  customer.phone ?? '',
                  customer.id,
                ].any((value) => value.toLowerCase().contains(query));
              }).toList();

              if (customers.isEmpty) {
                return _buildMessage(
                  'There are no registered customers yet.',
                  icon: Icons.people_outline_rounded,
                );
              }
              if (filteredCustomers.isEmpty) {
                return _buildMessage(
                  'No customers match "$_searchQuery".',
                  icon: Icons.search_off_rounded,
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 560
                      ? 2
                      : 1;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 172,
                    ),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) =>
                        _CustomerCard(customer: filteredCustomers[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customers',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Browse and find registered customer accounts.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search name, email, phone or ID',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _searchController.clear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
              filled: true,
              fillColor: AppColors.cardSurface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, {required IconData icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final StoreCustomer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => CustomerDetailsScreen(customer: customer),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CustomerAvatar(customer: customer),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _CustomerDetail(
                        icon: Icons.email_outlined,
                        text: customer.email ?? 'No email provided',
                      ),
                      const SizedBox(height: 4),
                      _CustomerDetail(
                        icon: Icons.phone_outlined,
                        text: customer.phone ?? 'No phone provided',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customer.createdAt == null
                            ? 'Customer ID · ${customer.id}'
                            : 'Joined ${_formatDate(customer.createdAt!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day} ${_monthName(date.month)} '
      '${date.year}';

  String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _CustomerAvatar extends StatelessWidget {
  final StoreCustomer customer;

  const _CustomerAvatar({required this.customer});

  @override
  Widget build(BuildContext context) {
    final imageUrl = customer.imageUrl;
    return CircleAvatar(
      radius: 31,
      backgroundColor: AppColors.primaryAccentMuted,
      child: imageUrl == null
          ? _fallbackAvatar()
          : ClipOval(
              child: Image.network(
                imageUrl,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
              ),
            ),
    );
  }

  Widget _fallbackAvatar() {
    return customer.name.trim().isEmpty
        ? const Icon(
            Icons.person_rounded,
            color: AppColors.primaryAccentLight,
            size: 30,
          )
        : Text(
            _initials(customer.name),
            style: const TextStyle(
              color: AppColors.primaryAccentLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _CustomerDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CustomerDetail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
