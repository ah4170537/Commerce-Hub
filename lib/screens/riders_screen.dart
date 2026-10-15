import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/orders_data_source.dart';
import '../services/rider_blocking_service.dart';
import '../services/riders_data_source.dart';
import 'orders_screen.dart';

class RidersScreen extends StatefulWidget {
  final RidersDataSource? dataSource;
  final RiderBlockingService? blockingService;
  final OrdersDataSource? ordersDataSource;

  const RidersScreen({
    super.key,
    this.dataSource,
    this.blockingService,
    this.ordersDataSource,
  });

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<StoreRider>> _ridersStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _ridersStream = (widget.dataSource ?? FirestoreRidersDataSource())
        .watchRiders();
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
          child: StreamBuilder<List<StoreRider>>(
            stream: _ridersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildMessage(
                  'Could not load riders.\n${snapshot.error}',
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

              final riders = snapshot.data!;
              final query = _searchQuery.trim().toLowerCase();
              final filteredRiders = riders.where((rider) {
                if (query.isEmpty) return true;
                return [
                  rider.name,
                  rider.email ?? '',
                  rider.phone ?? '',
                  rider.id,
                ].any((value) => value.toLowerCase().contains(query));
              }).toList();

              if (riders.isEmpty) {
                return _buildMessage(
                  'There are no registered riders yet.',
                  Icons.two_wheeler_rounded,
                );
              }
              if (filteredRiders.isEmpty) {
                return _buildMessage(
                  'No riders match "$_searchQuery".',
                  Icons.search_off_rounded,
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
                    itemCount: filteredRiders.length,
                    itemBuilder: (context, index) => _RiderCard(
                      rider: filteredRiders[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => RiderDetailsScreen(
                            rider: filteredRiders[index],
                            blockingService: widget.blockingService,
                            ordersDataSource: widget.ordersDataSource,
                          ),
                        ),
                      ),
                    ),
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
            'Riders',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Browse rider profiles and delivery histories.',
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

  Widget _buildMessage(String message, IconData icon) {
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

class _RiderCard extends StatelessWidget {
  final StoreRider rider;
  final VoidCallback onTap;

  const _RiderCard({required this.rider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBlocked = rider.details['isBlocked'] == true;
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _RiderAvatar(rider: rider, radius: 31),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        rider.name.isEmpty ? 'Unnamed rider' : rider.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _RiderContact(
                        icon: Icons.email_outlined,
                        text: rider.email ?? 'No email provided',
                      ),
                      const SizedBox(height: 4),
                      _RiderContact(
                        icon: Icons.phone_outlined,
                        text: rider.phone ?? 'No phone provided',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isBlocked
                            ? 'Rider blocked'
                            : rider.createdAt == null
                            ? 'Rider ID · ${rider.id}'
                            : 'Joined ${_formatDate(rider.createdAt!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isBlocked
                              ? AppColors.warning
                              : AppColors.textMuted,
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
      '${date.day} ${_monthName(date.month)} ${date.year}';

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

class _RiderAvatar extends StatelessWidget {
  final StoreRider rider;
  final double radius;

  const _RiderAvatar({required this.rider, required this.radius});

  @override
  Widget build(BuildContext context) {
    final imageUrl = rider.imageUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryAccentMuted,
      child: imageUrl == null
          ? _fallback()
          : ClipOval(
              child: Image.network(
                imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
            ),
    );
  }

  Widget _fallback() {
    final nameParts = rider.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final initials = nameParts.isEmpty
        ? '?'
        : nameParts.take(2).map((part) => part[0].toUpperCase()).join();
    return Text(
      initials,
      style: const TextStyle(
        color: AppColors.primaryAccentLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _RiderContact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RiderContact({required this.icon, required this.text});

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

class RiderDetailsScreen extends StatefulWidget {
  final StoreRider rider;
  final RiderBlockingService? blockingService;
  final OrdersDataSource? ordersDataSource;

  const RiderDetailsScreen({
    super.key,
    required this.rider,
    this.blockingService,
    this.ordersDataSource,
  });

  @override
  State<RiderDetailsScreen> createState() => _RiderDetailsScreenState();
}

class _RiderDetailsScreenState extends State<RiderDetailsScreen> {
  late bool _isBlocked = widget.rider.details['isBlocked'] == true;
  bool _isBlocking = false;

  Future<void> _confirmAndBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Block this rider?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${widget.rider.name} will be signed out of the rider app.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Block rider'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBlocking = true);
    try {
      await (widget.blockingService ?? FirestoreRiderBlockingService())
          .blockRider(widget.rider.id);
      if (!mounted) return;
      setState(() => _isBlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rider blocked.'),
          backgroundColor: AppColors.cardSurface,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not block rider: $error'),
          backgroundColor: AppColors.cardSurface,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderName = widget.rider.name.isEmpty ? 'Rider' : widget.rider.name;
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Rider details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildProfileCard(riderName),
          const SizedBox(height: 16),
          _buildActions(riderName),
          const SizedBox(height: 20),
          _buildInformationCard(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String riderName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _RiderAvatar(rider: widget.rider, radius: 44),
          const SizedBox(height: 14),
          Text(
            riderName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_isBlocked) ...[
            const SizedBox(height: 8),
            const Text(
              'Blocked',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(String riderName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isBlocking || _isBlocked ? null : _confirmAndBlock,
            icon: _isBlocking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.block_outlined),
            label: Text(
              _isBlocking
                  ? 'Blocking rider…'
                  : _isBlocked
                  ? 'Rider blocked'
                  : 'Block rider',
            ),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => OrdersScreen(
                  dataSource: widget.ordersDataSource,
                  initialFilter: OrderStatusFilter.delivered,
                  riderId: widget.rider.id,
                  riderPhone: widget.rider.phone,
                  riderName: riderName,
                ),
              ),
            ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text("Rider's deliveries"),
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
    final entries = widget.rider.details.entries
        .where((entry) => !_isHiddenField(entry.key))
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All rider information',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'No additional rider information is available.',
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
    final map = _mapEntries(value);
    final items = value is List ? value : null;
    final indentation = depth == 0 ? 0.0 : 12.0;

    if (map != null) {
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
            if (map.isEmpty)
              const Text(
                'Not provided',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...map.entries.map(
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

  bool _isHiddenField(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return const {
      'id',
      'uid',
      'userid',
      'riderid',
      'fcmtoken',
      'fcmtokens',
      'token',
      'password',
      'latitude',
      'longitude',
      'currentlatitude',
      'currentlongitude',
      'profileimage',
      'profileimageurl',
      'profileurl',
      'image',
      'imageurl',
      'photourl',
      'avatar',
      'avatarurl',
      'isblocked',
      'blockedat',
      'blockedby',
    }.contains(normalized);
  }

  Map<String, dynamic>? _mapEntries(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
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

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.cardSurface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
  );
}
