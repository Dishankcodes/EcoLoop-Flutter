import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import 'buying_order_details.dart';

class BuyingOrders extends StatefulWidget {
  const BuyingOrders({super.key});

  @override
  State<BuyingOrders> createState() => _BuyingOrdersState();
}

class _BuyingOrdersState extends State<BuyingOrders> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Packed',
    'Shipped',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Amount: Low to High',
    'Amount: High to Low',
  ];

  // DEMO BUYING ORDERS

  final List<Map<String, dynamic>> _orders = [
    {
      'orderId': 10021,
      'buyerId': 301,
      'sellerId': 101,
      'sellerType': 'artist',
      'productId': 1,
      'productTitle': 'Handcrafted Wooden Table',
      'sellerName': 'Creative Studio',
      'quantity': 1,
      'unitPrice': 4500.0,
      'totalAmount': 4500.0,
      'shippingAddress': 'Ahmedabad, Gujarat',
      'status': 'pending',
      'paymentStatus': 'paid',
      'createdAt': '2026-09-26',
      'updatedAt': '2026-09-26',
      'icon': Icons.table_restaurant_outlined,
    },
    {
      'orderId': 10018,
      'buyerId': 301,
      'sellerId': 105,
      'sellerType': 'artist',
      'productId': 2,
      'productTitle': 'Upcycled Glass Vase',
      'sellerName': 'Eco Art Studio',
      'quantity': 2,
      'unitPrice': 850.0,
      'totalAmount': 1700.0,
      'shippingAddress': 'Ahmedabad, Gujarat',
      'status': 'confirmed',
      'paymentStatus': 'paid',
      'createdAt': '2026-09-24',
      'updatedAt': '2026-09-25',
      'icon': Icons.local_drink_outlined,
    },
    {
      'orderId': 10014,
      'buyerId': 301,
      'sellerId': 109,
      'sellerType': 'artist',
      'productId': 4,
      'productTitle': 'Recycled Fabric Tote Bag',
      'sellerName': 'Green Craft',
      'quantity': 3,
      'unitPrice': 550.0,
      'totalAmount': 1650.0,
      'shippingAddress': 'Ahmedabad, Gujarat',
      'status': 'packed',
      'paymentStatus': 'paid',
      'createdAt': '2026-09-21',
      'updatedAt': '2026-09-22',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'orderId': 10009,
      'buyerId': 301,
      'sellerId': 112,
      'sellerType': 'artist',
      'productId': 7,
      'productTitle': 'Reclaimed Wood Wall Decor',
      'sellerName': 'Wood & Earth',
      'quantity': 1,
      'unitPrice': 1250.0,
      'totalAmount': 1250.0,
      'shippingAddress': 'Ahmedabad, Gujarat',
      'status': 'shipped',
      'paymentStatus': 'paid',
      'createdAt': '2026-09-18',
      'updatedAt': '2026-09-20',
      'icon': Icons.wallpaper_outlined,
    },
    {
      'orderId': 10003,
      'buyerId': 301,
      'sellerId': 114,
      'sellerType': 'artist',
      'productId': 8,
      'productTitle': 'Handmade Terracotta Planter',
      'sellerName': 'Earthy Hands',
      'quantity': 2,
      'unitPrice': 700.0,
      'totalAmount': 1400.0,
      'shippingAddress': 'Ahmedabad, Gujarat',
      'status': 'out_for_delivery',
      'paymentStatus': 'paid',
      'createdAt': '2026-09-14',
      'updatedAt': '2026-09-17',
      'icon': Icons.local_florist_outlined,
    },
    {
      'orderId': 9997,
      'buyerId': 301,
      'sellerId': 118,
      'sellerType': 'artist',
      'productId': 11,
      'productTitle': 'Recycled Paper Art Frame',
      'sellerName': 'Paper Stories',
      'quantity': 1,
      'unitPrice': 900.0,
      'totalAmount': 900.0,
      'shippingAddress': 'Ahmedabad, Gujarat',
      'status': 'delivered',
      'paymentStatus': 'paid',
      'createdAt': '2026-09-10',
      'updatedAt': '2026-09-15',
      'icon': Icons.image_outlined,
    },
    {
      'orderId': 9989,
      'buyerId': 301,
      'sellerId': 121,
      'sellerType': 'artist',
      'productId': 13,
      'productTitle': 'Upcycled Denim Cushion',
      'sellerName': 'ReNew Studio',
      'quantity': 2,
      'unitPrice': 600.0,
      'totalAmount': 1200.0,
      'shippingAddress': 'Ahmedabad, Gujarat',
      'status': 'cancelled',
      'paymentStatus': 'refunded',
      'createdAt': '2026-09-05',
      'updatedAt': '2026-09-06',
      'icon': Icons.weekend_outlined,
    },
  ];

  // LIFECYCLE

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FILTERED ORDERS

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
      _orders,
    );

    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      orders = orders.where((order) {
        final product = order['productTitle']?.toString().toLowerCase() ?? '';

        final seller = order['sellerName']?.toString().toLowerCase() ?? '';

        final orderId = order['orderId']?.toString().toLowerCase() ?? '';

        final productId = order['productId']?.toString().toLowerCase() ?? '';

        final address =
            order['shippingAddress']?.toString().toLowerCase() ?? '';

        return product.contains(query) ||
            seller.contains(query) ||
            orderId.contains(query) ||
            productId.contains(query) ||
            address.contains(query);
      }).toList();
    }

    if (_selectedFilter != 'All') {
      orders = orders.where((order) {
        return _displayStatus(order['status']) == _selectedFilter;
      }).toList();
    }

    switch (_selectedSort) {
      case 'Newest':
        orders.sort(
          (a, b) =>
              _dateValue(b['createdAt']).compareTo(_dateValue(a['createdAt'])),
        );
        break;

      case 'Oldest':
        orders.sort(
          (a, b) =>
              _dateValue(a['createdAt']).compareTo(_dateValue(b['createdAt'])),
        );
        break;

      case 'Amount: Low to High':
        orders.sort(
          (a, b) => _amountValue(
            a['totalAmount'],
          ).compareTo(_amountValue(b['totalAmount'])),
        );
        break;

      case 'Amount: High to Low':
        orders.sort(
          (a, b) => _amountValue(
            b['totalAmount'],
          ).compareTo(_amountValue(a['totalAmount'])),
        );
        break;
    }

    return orders;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

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
          'Buying Orders',
          style: ArtistTextStyles.title.copyWith(fontSize: 19),
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
            child: orders.isEmpty
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
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
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
        controller: _searchController,

        onChanged: (_) {
          setState(() {});
        },

        style: ArtistTextStyles.bodyMedium,

        cursorColor: ArtistColors.primary,

        decoration: InputDecoration(
          hintText: 'Search your orders...',
          hintStyle: ArtistTextStyles.hint,

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ArtistColors.primary,
          ),

          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {});
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
            horizontal: 16,
            vertical: 14,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: ArtistColors.border),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: ArtistColors.primary,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  // SUMMARY

  Widget _buildSummary() {
    final total = _orders.length;

    final active = _orders.where((order) {
      final status = order['status']?.toString();

      return status != 'delivered' && status != 'cancelled';
    }).length;

    final delivered = _orders.where((order) {
      return order['status'] == 'delivered';
    }).length;

    final totalSpent = _orders
        .where((order) {
          return order['status'] != 'cancelled';
        })
        .fold<double>(
          0,
          (sum, order) => sum + _amountValue(order['totalAmount']),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.receipt_long_outlined,
              value: '$total',
              label: 'Orders',
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: _buildSummaryCard(
              icon: Icons.local_shipping_outlined,
              value: '$active',
              label: 'Active',
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: _buildSummaryCard(
              icon: Icons.check_circle_outline_rounded,
              value: '$delivered',
              label: 'Delivered',
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: _buildSummaryCard(
              icon: Icons.currency_rupee_rounded,
              value: _formatCompactAmount(totalSpent),
              label: 'Spent',
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: ArtistColors.primary, size: 19),

          const SizedBox(height: 6),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArtistTextStyles.small.copyWith(fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  // FILTER CHIPS

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];

          final selected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? ArtistColors.primary : ArtistColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? ArtistColors.primary : ArtistColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: selected
                      ? ArtistTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        )
                      : ArtistTextStyles.small.copyWith(
                          color: ArtistColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ORDER CARD

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String status = order['status']?.toString() ?? 'pending';

    final Color statusColor = _statusColor(status);

    final IconData statusIcon = _statusIcon(status);

    final double amount = _amountValue(order['totalAmount']);

    final int quantity = int.tryParse(order['quantity']?.toString() ?? '') ?? 1;

    return GestureDetector(
      onTap: () {
        _openOrderDetails(order);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ArtistColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // TOP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    order['icon'] as IconData? ?? Icons.shopping_bag_outlined,
                    size: 30,
                    color: ArtistColors.primary,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['productTitle']?.toString() ?? 'Product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Order #${order['orderId']}',
                        style: ArtistTextStyles.small,
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _formatDate(order['createdAt']),
                        style: ArtistTextStyles.small,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  _formatCurrency(amount),
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.primary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Divider(height: 1, color: ArtistColors.border.withOpacity(0.75)),

            const SizedBox(height: 12),

            // STATUS + PAYMENT + QUANTITY
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),

                      const SizedBox(width: 5),

                      Text(
                        _displayStatus(status),
                        style: ArtistTextStyles.small.copyWith(
                          color: statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: order['paymentStatus'] == 'paid'
                        ? ArtistColors.success.withOpacity(0.09)
                        : ArtistColors.warning.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatPaymentStatus(order['paymentStatus']),
                    style: ArtistTextStyles.small.copyWith(
                      color: order['paymentStatus'] == 'paid'
                          ? ArtistColors.success
                          : ArtistColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),

                Text(
                  '$quantity '
                  '${quantity == 1 ? 'item' : 'items'}',
                  style: ArtistTextStyles.small,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // SELLER + LOCATION
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: ArtistColors.textSecondary,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    order['sellerName']?.toString() ?? 'Seller',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.small.copyWith(fontSize: 11),
                  ),
                ),

                const SizedBox(width: 10),

                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: ArtistColors.textSecondary,
                ),

                const SizedBox(width: 4),

                Flexible(
                  child: Text(
                    order['shippingAddress']?.toString() ?? 'Delivery address',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // VIEW DETAILS
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () {
                  _openOrderDetails(order);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArtistColors.primary,
                  side: const BorderSide(
                    color: ArtistColors.primary,
                    width: 1.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.visibility_outlined, size: 17),

                    const SizedBox(width: 7),

                    Text(
                      'View Order Details',
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // OPEN ORDER DETAILS

  void _openOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuyingOrderDetails(order: order)),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    final bool hasSearch = _searchController.text.trim().isNotEmpty;

    final bool hasFilter = _selectedFilter != 'All';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: ArtistColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: ArtistColors.primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              hasSearch || hasFilter ? 'No Orders Found' : 'No Purchases Yet',
              style: ArtistTextStyles.title.copyWith(fontSize: 19),
            ),

            const SizedBox(height: 7),

            Text(
              hasSearch
                  ? 'Try searching with a different product or order ID.'
                  : hasFilter
                  ? 'You do not have any orders in this status yet.'
                  : 'Products you purchase from the marketplace will appear here.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),

            const SizedBox(height: 20),

            if (hasSearch || hasFilter)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'All';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Reset Filters',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArtistColors.primary,
                  side: const BorderSide(color: ArtistColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: SingleChildScrollView(
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
                          Navigator.pop(context);
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
                    final selected = _selectedSort == option;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,

                      onTap: () {
                        setState(() {
                          _selectedSort = option;
                        });

                        Navigator.pop(context);
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
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {});
  }

  // STATUS HELPERS

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ArtistColors.warning;

      case 'confirmed':
        return ArtistColors.info;

      case 'packed':
        return ArtistColors.primary;

      case 'shipped':
        return ArtistColors.info;

      case 'out_for_delivery':
        return ArtistColors.accent;

      case 'delivered':
        return ArtistColors.success;

      case 'cancelled':
        return ArtistColors.error;

      default:
        return ArtistColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;

      case 'confirmed':
        return Icons.check_circle_outline_rounded;

      case 'packed':
        return Icons.inventory_2_outlined;

      case 'shipped':
        return Icons.local_shipping_outlined;

      case 'out_for_delivery':
        return Icons.delivery_dining_outlined;

      case 'delivered':
        return Icons.check_circle_rounded;

      case 'cancelled':
        return Icons.cancel_outlined;

      default:
        return Icons.info_outline_rounded;
    }
  }

  String _displayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';

      case 'confirmed':
        return 'Confirmed';

      case 'packed':
        return 'Packed';

      case 'shipped':
        return 'Shipped';

      case 'out_for_delivery':
        return 'Out for Delivery';

      case 'delivered':
        return 'Delivered';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

  String _formatPaymentStatus(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'paid':
        return 'Paid';

      case 'pending':
        return 'Payment Pending';

      case 'refunded':
        return 'Refunded';

      case 'failed':
        return 'Failed';

      default:
        return status?.toString() ?? 'Pending';
    }
  }

  // VALUE HELPERS

  double _amountValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _dateValue(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime(2000);
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) {
      return value?.toString() ?? '-';
    }

    const months = [
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
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _formatCurrency(double amount) {
    if (amount == amount.roundToDouble()) {
      return '₹${amount.toInt()}';
    }

    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatCompactAmount(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }

    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }

    return '₹${amount.toInt()}';
  }
}
