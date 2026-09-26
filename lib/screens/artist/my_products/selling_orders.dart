import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class SellingOrders extends StatefulWidget {
  const SellingOrders({super.key});

  @override
  State<SellingOrders> createState() => _SellingOrdersState();
}

class _SellingOrdersState extends State<SellingOrders> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Processing',
    'Completed',
    'Cancelled',
  ];

  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#EL-1024',
      'product': 'Upcycled Wooden Table',
      'customer': 'Rahul Patel',
      'date': '26 Sep 2026',
      'price': 4500,
      'quantity': 1,
      'status': 'Pending',
    },
    {
      'id': '#EL-1023',
      'product': 'Handmade Wall Decor',
      'customer': 'Priya Shah',
      'date': '25 Sep 2026',
      'price': 1800,
      'quantity': 2,
      'status': 'Confirmed',
    },
    {
      'id': '#EL-1022',
      'product': 'Recycled Storage Box',
      'customer': 'Aarav Mehta',
      'date': '24 Sep 2026',
      'price': 850,
      'quantity': 3,
      'status': 'Processing',
    },
    {
      'id': '#EL-1021',
      'product': 'Vintage Lamp',
      'customer': 'Kavya Desai',
      'date': '22 Sep 2026',
      'price': 2200,
      'quantity': 1,
      'status': 'Completed',
    },
    {
      'id': '#EL-1020',
      'product': 'Upcycled Denim Bag',
      'customer': 'Neha Joshi',
      'date': '20 Sep 2026',
      'price': 1200,
      'quantity': 2,
      'status': 'Completed',
    },
    {
      'id': '#EL-1019',
      'product': 'Recycled Bookshelf',
      'customer': 'Dev Patel',
      'date': '18 Sep 2026',
      'price': 3200,
      'quantity': 1,
      'status': 'Cancelled',
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') {
      return _orders;
    }

    return _orders.where((order) {
      return order['status'] == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ArtistColors.background,
        elevation: 0,
        title: Text(
          'Selling Orders',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSummary(),
          const SizedBox(height: 18),
          _buildFilters(),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Orders',
              value: '18',
              icon: Icons.receipt_long_outlined,
              color: ArtistColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              title: 'Pending',
              value: '6',
              icon: Icons.pending_actions_outlined,
              color: ArtistColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              title: 'Completed',
              value: '9',
              icon: Icons.check_circle_outline_rounded,
              color: ArtistColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArtistTextStyles.small,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTERS
  // ─────────────────────────────────────────────

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(
              filter,
              style: ArtistTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : ArtistColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            selectedColor: ArtistColors.primary,
            backgroundColor: ArtistColors.surface,
            side: BorderSide(
              color: isSelected ? ArtistColors.primary : ArtistColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ORDERS LIST
  // ─────────────────────────────────────────────

  Widget _buildOrdersList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];

        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;

    return InkWell(
      onTap: () => _showOrderDetails(order),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ArtistColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(order),
            const SizedBox(height: 14),
            _buildProductInfo(order),
            const SizedBox(height: 14),
            const Divider(height: 1, color: ArtistColors.border),
            const SizedBox(height: 12),
            _buildOrderBottom(order, status),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ORDER HEADER
  // ─────────────────────────────────────────────

  Widget _buildOrderHeader(Map<String, dynamic> order) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ArtistColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: ArtistColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order['id'],
                style: ArtistTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(order['date'], style: ArtistTextStyles.small),
            ],
          ),
        ),
        _buildStatusBadge(order['status']),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // PRODUCT INFO
  // ─────────────────────────────────────────────

  Widget _buildProductInfo(Map<String, dynamic> order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: ArtistColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.image_outlined,
            color: ArtistColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order['product'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: ArtistColors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      order['customer'],
                      style: ArtistTextStyles.small,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 15,
                    color: ArtistColors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Quantity: ${order['quantity']}',
                    style: ArtistTextStyles.small,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM ROW
  // ─────────────────────────────────────────────

  Widget _buildOrderBottom(Map<String, dynamic> order, String status) {
    return Row(
      children: [
        Text(
          'Total',
          style: ArtistTextStyles.small.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 7),
        Text(
          '₹${order['price']}',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 17,
            color: ArtistColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          'View Details',
          style: ArtistTextStyles.caption.copyWith(
            color: ArtistColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 12,
          color: ArtistColors.primary,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STATUS BADGE
  // ─────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: ArtistTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return ArtistColors.warning;

      case 'Confirmed':
        return ArtistColors.info;

      case 'Processing':
        return ArtistColors.primary;

      case 'Completed':
        return ArtistColors.success;

      case 'Cancelled':
        return ArtistColors.error;

      default:
        return ArtistColors.textSecondary;
    }
  }

  // ─────────────────────────────────────────────
  // ORDER DETAILS
  // ─────────────────────────────────────────────

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ArtistColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order Details',
                        style: ArtistTextStyles.title,
                      ),
                    ),
                    _buildStatusBadge(order['status']),
                  ],
                ),

                const SizedBox(height: 22),

                _buildDetailRow(
                  Icons.receipt_long_outlined,
                  'Order ID',
                  order['id'],
                ),

                _buildDetailRow(
                  Icons.calendar_today_outlined,
                  'Order Date',
                  order['date'],
                ),

                _buildDetailRow(
                  Icons.person_outline_rounded,
                  'Customer',
                  order['customer'],
                ),

                _buildDetailRow(
                  Icons.inventory_2_outlined,
                  'Product',
                  order['product'],
                ),

                _buildDetailRow(
                  Icons.shopping_bag_outlined,
                  'Quantity',
                  '${order['quantity']}',
                ),

                _buildDetailRow(
                  Icons.currency_rupee_rounded,
                  'Total Amount',
                  '₹${order['price']}',
                ),

                const SizedBox(height: 18),

                _buildActionButton(order),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: ArtistColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ArtistTextStyles.small),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> order) {
    final status = order['status'] as String;

    if (status == 'Pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showMessage('Order confirmed successfully.');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ArtistColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Confirm Order', style: ArtistTextStyles.button),
        ),
      );
    }

    if (status == 'Confirmed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showMessage('Order moved to processing.');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ArtistColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Start Processing', style: ArtistTextStyles.button),
        ),
      );
    }

    if (status == 'Processing') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showMessage('Order marked as completed.');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ArtistColors.success,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Mark as Completed', style: ArtistTextStyles.button),
        ),
      );
    }

    if (status == 'Completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: ArtistColors.success.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: ArtistColors.success,
              size: 19,
            ),
            const SizedBox(width: 8),
            Text(
              'Order Completed',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: ArtistColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: ArtistColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cancel_outlined,
            color: ArtistColors.error,
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            'Order Cancelled',
            style: ArtistTextStyles.bodyMedium.copyWith(
              color: ArtistColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ArtistColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No orders found',
              style: ArtistTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 7),
            Text(
              _selectedFilter == 'All'
                  ? 'Your selling orders will appear here.'
                  : 'There are no $_selectedFilter orders.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MESSAGE
  // ─────────────────────────────────────────────

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: ArtistColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
