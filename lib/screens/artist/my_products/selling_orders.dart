import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'selling_order_details.dart';

class SellingOrders extends StatefulWidget {
  const SellingOrders({super.key});

  @override
  State<SellingOrders> createState() => _SellingOrdersState();
}

class _SellingOrdersState extends State<SellingOrders> {
  // Shared in-memory cache keeps the page instant when revisiting it.
  static List<Map<String, dynamic>>? _cachedOrders;
  static DateTime? _ordersCachedAt;
  static Future<dynamic>? _ordersRequest;
  static const Duration _cacheDuration = Duration(minutes: 2);
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Packed',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Amount: Low to High',
    'Amount: High to Low',
  ];

  // Live orders from the artist's account in Google Sheets.
  final List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool forceRefresh = false}) async {
    final cached = _cachedOrders;
    final cachedAt = _ordersCachedAt;
    final cacheIsFresh =
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheDuration;

    // Show previously loaded orders immediately. Only the first-ever load
    // needs to block the list with a full-screen loading indicator.
    if (cached != null && mounted) {
      setState(() {
        _orders
          ..clear()
          ..addAll(cached.map((order) => Map<String, dynamic>.from(order)));
        _isLoading = false;
        _loadError = null;
      });
      if (cacheIsFresh && !forceRefresh) return;
    } else if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final request = _ordersRequest ??= EcoLoopApi.instance.get(
        '/artist/orders',
      );
      final dynamic response = await request;
      final List<dynamic> rows = response is List
          ? response
          : response is Map && response['orders'] is List
          ? response['orders'] as List
          : <dynamic>[];
      final loaded = rows.whereType<Map>().map((raw) {
        final order = Map<String, dynamic>.from(raw);
        order['productTitle'] =
            order['productTitle'] ??
            order['productName'] ??
            order['title'] ??
            'Product';
        order['createdAt'] = order['createdAt'] ?? '';
        order['updatedAt'] = order['updatedAt'] ?? '';
        order['totalAmount'] =
            order['totalAmount'] ??
            order['subtotal'] ??
            (_toDouble(order['unitPrice']) * _toDouble(order['quantity']));
        return order;
      }).toList();

      _cachedOrders = loaded
          .map((order) => Map<String, dynamic>.from(order))
          .toList();
      _ordersCachedAt = DateTime.now();
      _ordersRequest = null;

      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      _ordersRequest = null;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Keep already-rendered cached orders if a background refresh fails.
        if (_orders.isEmpty) {
          _loadError = error.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: ArtistColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load selling orders',
              style: ArtistTextStyles.title.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              _loadError ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.small,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FILTERED + SORTED ORDERS

  List<Map<String, dynamic>> get _filteredOrders {
    final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
      _orders,
    );

    final String query = _searchQuery.trim().toLowerCase();

    // -------------------------------------------------------------------------

    // SEARCH
    // -------------------------------------------------------------------------

    if (query.isNotEmpty) {
      orders.retainWhere((order) {
        final String orderId = '${order['orderId'] ?? ''}'.toLowerCase();

        final String product = '${order['productTitle'] ?? ''}'.toLowerCase();

        final String buyerId = '${order['buyerId'] ?? ''}'.toLowerCase();

        final String address = '${order['shippingAddress'] ?? ''}'
            .toLowerCase();

        final String productId = '${order['productId'] ?? ''}'.toLowerCase();

        return orderId.contains(query) ||
            product.contains(query) ||
            buyerId.contains(query) ||
            address.contains(query) ||
            productId.contains(query);
      });
    }

    // -------------------------------------------------------------------------
    // STATUS FILTER
    // -------------------------------------------------------------------------

    if (_selectedFilter != 'All') {
      final String selectedStatus = _selectedFilter.toLowerCase();

      orders.retainWhere((order) {
        final String status = '${order['status'] ?? ''}'.toLowerCase();

        return status == selectedStatus;
      });
    }

    // -------------------------------------------------------------------------
    // SORT
    // -------------------------------------------------------------------------

    switch (_selectedSort) {
      case 'Oldest':
        orders.sort((a, b) {
          final String dateA = '${a['createdAt'] ?? ''}';

          final String dateB = '${b['createdAt'] ?? ''}';

          return dateA.compareTo(dateB);
        });
        break;

      case 'Amount: Low to High':
        orders.sort((a, b) {
          return _toDouble(
            a['totalAmount'],
          ).compareTo(_toDouble(b['totalAmount']));
        });
        break;

      case 'Amount: High to Low':
        orders.sort((a, b) {
          return _toDouble(
            b['totalAmount'],
          ).compareTo(_toDouble(a['totalAmount']));
        });
        break;

      case 'Newest':
      default:
        orders.sort((a, b) {
          final String dateA = '${a['createdAt'] ?? ''}';

          final String dateB = '${b['createdAt'] ?? ''}';

          return dateB.compareTo(dateA);
        });
        break;
    }

    return orders;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> orders = _filteredOrders;

    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
        ),

        title: Text(
          'Selling Orders',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _showSortSheet,
            tooltip: 'Sort',
            icon: const Icon(
              Icons.sort_rounded,
              color: ArtistColors.textPrimary,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          _buildSearch(),

          _buildSummary(),

          _buildFilterChips(),

          const SizedBox(height: 4),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? _buildLoadError()
                : orders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: ArtistColors.primary,
                    onRefresh: _refreshOrders,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      itemCount: orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildOrderCard(orders[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // SEARCH

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },

        style: ArtistTextStyles.body.copyWith(
          color: ArtistColors.textPrimary,
          fontSize: 13,
        ),

        decoration: InputDecoration(
          hintText: 'Search orders...',
          hintStyle: ArtistTextStyles.hint,

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ArtistColors.primary,
          ),

          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ArtistColors.textSecondary,
                  ),
                )
              : null,

          filled: true,
          fillColor: ArtistColors.surface,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: ArtistColors.border),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: ArtistColors.border),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: ArtistColors.primary,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // SUMMARY

  Widget _buildSummary() {
    final int total = _orders.length;

    final int pending = _orders.where((order) {
      return '${order['status'] ?? ''}'.toLowerCase() == 'pending';
    }).length;

    final int delivered = _orders.where((order) {
      return '${order['status'] ?? ''}'.toLowerCase() == 'delivered';
    }).length;

    final double revenue = _orders.fold<double>(0, (sum, order) {
      return sum + _toDouble(order['totalAmount']);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.receipt_long_outlined,
                  value: '$total',
                  label: 'Orders',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.pending_actions_outlined,
                  value: '$pending',
                  label: 'Pending',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$delivered',
                  label: 'Delivered',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ArtistColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.currency_rupee_rounded,
                    color: ArtistColors.primary,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 10),

                Text('Order Value', style: ArtistTextStyles.small),

                const Spacer(),

                Text(
                  '₹${_formatPrice(revenue)}',
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 16,
                    color: ArtistColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: ArtistColors.primary),

          const SizedBox(height: 5),

          Text(value, style: ArtistTextStyles.title.copyWith(fontSize: 17)),

          const SizedBox(height: 1),

          Text(label, style: ArtistTextStyles.small),
        ],
      ),
    );
  }

  // FILTER CHIPS

  Widget _buildFilterChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,

        separatorBuilder: (context, index) => const SizedBox(width: 8),

        itemBuilder: (context, index) {
          final String filter = _filters[index];

          final bool selected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),

            selected: selected,

            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },

            labelStyle: selected
                ? ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.primary,
                    fontSize: 11,
                  )
                : ArtistTextStyles.body.copyWith(fontSize: 11),

            backgroundColor: ArtistColors.surface,

            selectedColor: ArtistColors.light,

            side: BorderSide(
              color: selected ? ArtistColors.primary : ArtistColors.border,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  // ORDER CARD

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        // IMPORTANT:
        // Clicking anywhere on the card opens
        // the complete SellingOrderDetails page.
        onTap: () {
          _openOrderDetails(order);
        },

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderIcon(order),

                  const SizedBox(width: 12),

                  Expanded(child: _buildOrderInfo(order)),

                  _buildOrderMenu(order),
                ],
              ),

              const SizedBox(height: 14),

              Divider(height: 1, color: ArtistColors.border),

              const SizedBox(height: 12),

              _buildOrderMeta(order),

              const SizedBox(height: 12),

              _buildOrderActions(order),
            ],
          ),
        ),
      ),
    );
  }

  // OPEN ORDER DETAILS

  void _openOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellingOrderDetails(order: order)),
    ).then((_) {
      if (mounted) _loadOrders();
    });
  }

  // ORDER ICON

  Widget _buildOrderIcon(Map<String, dynamic> order) {
    final String status = '${order['status'] ?? ''}';

    final Color color = _statusColor(status);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(_statusIcon(status), color: color, size: 26),
    );
  }

  // ORDER INFO

  Widget _buildOrderInfo(Map<String, dynamic> order) {
    final String product = '${order['productTitle'] ?? 'Product'}';

    final String orderId = '${order['orderId'] ?? '-'}';

    final String status = '${order['status'] ?? ''}';

    final String paymentStatus = '${order['paymentStatus'] ?? ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 14),
        ),

        const SizedBox(height: 5),

        Text('Order #$orderId', style: ArtistTextStyles.small),

        const SizedBox(height: 6),

        Wrap(
          spacing: 7,
          runSpacing: 5,
          children: [
            _buildStatusBadge(status),

            _buildPaymentBadge(paymentStatus),
          ],
        ),
      ],
    );
  }

  // ORDER MENU

  Widget _buildOrderMenu(Map<String, dynamic> order) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,

      icon: const Icon(
        Icons.more_vert_rounded,
        color: ArtistColors.textSecondary,
        size: 21,
      ),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      onSelected: (value) {
        if (value == 'view') {
          _openOrderDetails(order);
        }
      },

      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, color: ArtistColors.primary),

              SizedBox(width: 10),

              Text('View Details'),
            ],
          ),
        ),
      ],
    );
  }

  // ORDER META

  Widget _buildOrderMeta(Map<String, dynamic> order) {
    final String buyerId = '${order['buyerId'] ?? '-'}';

    final String quantity = '${order['quantity'] ?? '0'}';

    final String location = '${order['shippingAddress'] ?? '-'}';

    return Row(
      children: [
        Expanded(
          child: _buildMetaItem(
            icon: Icons.person_outline_rounded,
            label: 'Buyer',
            value: 'Buyer #$buyerId',
          ),
        ),

        Expanded(
          child: _buildMetaItem(
            icon: Icons.inventory_2_outlined,
            label: 'Quantity',
            value: quantity,
          ),
        ),

        Expanded(
          child: _buildMetaItem(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: _shortLocation(location),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: ArtistColors.textSecondary),

        const SizedBox(height: 3),

        Text(label, style: ArtistTextStyles.small.copyWith(fontSize: 9.5)),

        const SizedBox(height: 1),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  // ORDER ACTIONS

  Widget _buildOrderActions(Map<String, dynamic> order) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _openOrderDetails(order);
        },

        icon: const Icon(Icons.visibility_outlined, size: 17),

        label: const Text('View Details'),

        style: OutlinedButton.styleFrom(
          foregroundColor: ArtistColors.primary,

          side: const BorderSide(color: ArtistColors.primary),

          padding: const EdgeInsets.symmetric(vertical: 11),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          textStyle: ArtistTextStyles.bodyMedium.copyWith(fontSize: 11),
        ),
      ),
    );
  }

  // STATUS BADGE

  Widget _buildStatusBadge(String status) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),

      child: Text(
        _formatStatus(status),

        style: ArtistTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  // PAYMENT BADGE

  Widget _buildPaymentBadge(String paymentStatus) {
    final String value = paymentStatus.toLowerCase();

    final Color color = value == 'paid'
        ? ArtistColors.success
        : value == 'refunded'
        ? ArtistColors.warning
        : ArtistColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),

      child: Text(
        _formatStatus(paymentStatus),

        style: ArtistTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: ArtistColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: ArtistColors.primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'No Orders Found',
              style: ArtistTextStyles.title.copyWith(fontSize: 19),
            ),

            const SizedBox(height: 7),

            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with a different order ID or product.'
                  : 'You do not have any orders in this category yet.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'All';
                  _searchQuery = '';
                  _selectedSort = 'Newest';
                });
              },

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Reset Filters'),

              style: OutlinedButton.styleFrom(
                foregroundColor: ArtistColors.primary,

                side: const BorderSide(color: ArtistColors.primary),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SORT SHEET

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),

      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sort Orders',
                        style: ArtistTextStyles.title.copyWith(fontSize: 19),
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: ArtistColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ..._sortOptions.map((option) {
                    final bool selected = _selectedSort == option;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,

                      onTap: () {
                        setState(() {
                          _selectedSort = option;
                        });

                        Navigator.pop(sheetContext);
                      },

                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,

                        color: selected
                            ? ArtistColors.primary
                            : ArtistColors.textMuted,
                      ),

                      title: Text(
                        option,
                        style: selected
                            ? ArtistTextStyles.bodyMedium
                            : ArtistTextStyles.body,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // REFRESH

  Future<void> _refreshOrders() async {
    await _loadOrders(forceRefresh: true);
  }

  // STATUS COLOR

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ArtistColors.warning;

      case 'confirmed':
        return ArtistColors.info;

      case 'packed':
        return ArtistColors.primary;

      case 'shipped':
        return ArtistColors.accent;

      case 'out_for_delivery':
        return ArtistColors.secondary;

      case 'delivered':
        return ArtistColors.success;

      case 'cancelled':
        return ArtistColors.error;

      default:
        return ArtistColors.textSecondary;
    }
  }

  // STATUS ICON

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions_outlined;

      case 'confirmed':
        return Icons.check_circle_outline_rounded;

      case 'packed':
        return Icons.inventory_2_outlined;

      case 'shipped':
        return Icons.local_shipping_outlined;

      case 'out_for_delivery':
        return Icons.delivery_dining_outlined;

      case 'delivered':
        return Icons.task_alt_rounded;

      case 'cancelled':
        return Icons.cancel_outlined;

      default:
        return Icons.receipt_long_outlined;
    }
  }

  // FORMAT STATUS

  String _formatStatus(String status) {
    final String safeStatus = status.trim();

    if (safeStatus.isEmpty) {
      return '-';
    }

    return safeStatus
        .split('_')
        .map((part) {
          if (part.isEmpty) {
            return '';
          }

          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
  }

  // SHORT LOCATION

  String _shortLocation(String location) {
    final String safeLocation = location.trim();

    if (safeLocation.isEmpty) {
      return '-';
    }

    if (safeLocation.length <= 18) {
      return safeLocation;
    }

    return '${safeLocation.substring(0, 16)}...';
  }

  // SAFE DOUBLE CONVERSION

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final String stringValue = '${value ?? ''}'.trim();

    return double.tryParse(stringValue) ?? 0.0;
  }

  // PRICE FORMAT

  String _formatPrice(dynamic value) {
    final double price = _toDouble(value);

    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }

    return price.toStringAsFixed(2);
  }
}
