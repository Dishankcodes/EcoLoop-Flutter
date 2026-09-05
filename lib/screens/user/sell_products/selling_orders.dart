import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import 'selling_order_details.dart';

class SellingOrders extends StatefulWidget {
  const SellingOrders({super.key});

  @override
  State<SellingOrders> createState() => _SellingOrdersState();
}

class _SellingOrdersState extends State<SellingOrders> {
  // ============================================================
  // DUMMY SELLING ORDERS
  // ============================================================

  final List<Map<String, dynamic>> _sellingOrders = [
    {
      'product': 'Old Wooden Chair',
      'price': '₹1,200',
      'date': '27 Aug 2026',
      'status': 'Completed',
      'statusColor': AppColors.success,
      'icon': Icons.chair_outlined,
      'orderId': '#EL1008',
      'buyer': 'Aarav Shah',
      'quantity': 1,
      'payment': 'Paid',
    },
    {
      'product': 'Desk Lamp',
      'price': '₹650',
      'date': '31 Aug 2026',
      'status': 'Processing',
      'statusColor': Colors.orange,
      'icon': Icons.light_outlined,
      'orderId': '#EL1029',
      'buyer': 'Riya Patel',
      'quantity': 1,
      'payment': 'Paid',
    },
    {
      'product': 'Canvas Art Frame',
      'price': '₹900',
      'date': '01 Sep 2026',
      'status': 'New Order',
      'statusColor': AppColors.primary,
      'icon': Icons.image_outlined,
      'orderId': '#EL1034',
      'buyer': 'Dev Mehta',
      'quantity': 1,
      'payment': 'Paid',
    },
    {
      'product': 'Wooden Storage Box',
      'price': '₹1,450',
      'date': '02 Sep 2026',
      'status': 'Shipped',
      'statusColor': Colors.blue,
      'icon': Icons.inventory_2_outlined,
      'orderId': '#EL1038',
      'buyer': 'Meera Joshi',
      'quantity': 2,
      'payment': 'Paid',
    },
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                children: [
                  _buildEarningsCard(),
                  const SizedBox(height: 24),
                  _buildOrderSectionHeader(),
                  const SizedBox(height: 12),
                  _buildOrders(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selling Orders',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage orders from your buyers',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EARNINGS CARD
  // ============================================================

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.82)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Selling Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Seller Hub',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            '₹4,200',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            'Total sales value',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),

          const SizedBox(height: 18),

          Divider(height: 1, color: Colors.white.withOpacity(0.20)),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildEarningItem(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Completed',
                  value: '₹1,200',
                ),
              ),
              Container(
                height: 38,
                width: 1,
                color: Colors.white.withOpacity(0.18),
              ),
              Expanded(
                child: _buildEarningItem(
                  icon: Icons.schedule_rounded,
                  title: 'Pending',
                  value: '₹3,000',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.white70),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildOrderSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Order History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_sellingOrders.length} Orders',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ORDERS
  // ============================================================

  Widget _buildOrders() {
    if (_sellingOrders.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _sellingOrders.map((order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildSellingOrderCard(order),
        );
      }).toList(),
    );
  }

  // ============================================================
  // SELLING ORDER CARD
  // ============================================================

  Widget _buildSellingOrderCard(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Icon
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(order['icon'], size: 31, color: AppColors.primary),
              ),

              const SizedBox(width: 13),

              // Product Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['product'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Order ${order['orderId']}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      order['date'],
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order['price'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty ${order['quantity']}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(height: 1, color: AppColors.accent.withOpacity(0.25)),

          const SizedBox(height: 12),

          // Buyer + Payment
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Buyer: ${order['buyer']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order['payment'],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status + Details
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: order['statusColor'].withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 7,
                      width: 7,
                      decoration: BoxDecoration(
                        color: order['statusColor'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order['status'],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: order['statusColor'],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellingOrderDetails(order: order),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 15),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 45),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            height: 88,
            width: 88,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 42,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'No sales yet',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'When someone buys an item from your listings, '
            'the order will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 45,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
              label: const Text('Back to Orders'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
