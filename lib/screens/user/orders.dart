import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import 'buying_order_details.dart';
import 'selling_order_details.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildBuyingOrders(), _buildSellingOrders()],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Orders',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Track your purchases and sales',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: Icon(Icons.shopping_bag_outlined, size: 19),
            text: 'Buying',
          ),
          Tab(icon: Icon(Icons.sell_outlined, size: 19), text: 'Selling'),
        ],
      ),
    );
  }

  // ============================================================
  // BUYING
  // ============================================================

  Widget _buildBuyingOrders() {
    final orders = [
      {
        'product': 'Wooden Study Table',
        'price': '₹2,500',
        'date': '28 Aug 2026',
        'status': 'Delivered',
        'statusColor': AppColors.success,
        'icon': Icons.table_restaurant_outlined,
        'orderId': '#EL1024',
      },
      {
        'product': 'Glass Bottle Set',
        'price': '₹450',
        'date': '30 Aug 2026',
        'status': 'Shipped',
        'statusColor': Colors.orange,
        'icon': Icons.local_drink_outlined,
        'orderId': '#EL1028',
      },
      {
        'product': 'Recycled Paper Bundle',
        'price': '₹180',
        'date': '01 Sep 2026',
        'status': 'Confirmed',
        'statusColor': AppColors.primary,
        'icon': Icons.description_outlined,
        'orderId': '#EL1032',
      },
    ];

    return _buildOrderList(
      orders,
      emptyTitle: 'No purchases yet',
      emptyDescription: 'Items you buy from the marketplace will appear here.',
    );
  }

  // ============================================================
  // SELLING
  // ============================================================

  Widget _buildSellingOrders() {
    final orders = [
      {
        'product': 'Old Wooden Chair',
        'price': '₹1,200',
        'date': '27 Aug 2026',
        'status': 'Completed',
        'statusColor': AppColors.success,
        'icon': Icons.chair_outlined,
        'orderId': '#EL1008',
      },
      {
        'product': 'Desk Lamp',
        'price': '₹650',
        'date': '31 Aug 2026',
        'status': 'Processing',
        'statusColor': Colors.orange,
        'icon': Icons.light_outlined,
        'orderId': '#EL1029',
      },
      {
        'product': 'Canvas Art Frame',
        'price': '₹900',
        'date': '01 Sep 2026',
        'status': 'New Order',
        'statusColor': AppColors.primary,
        'icon': Icons.image_outlined,
        'orderId': '#EL1034',
      },
    ];

    return Column(
      children: [
        _buildEarningsCard(),
        Expanded(
          child: _buildOrderList(
            orders,
            emptyTitle: 'No sales yet',
            emptyDescription:
                'Orders received for your listed items will appear here.',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EARNINGS
  // ============================================================

  Widget _buildEarningsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Earnings',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Seller Hub',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '₹2,750',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Completed  ₹1,200',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                'Pending  ₹1,550',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER LIST
  // ============================================================

  Widget _buildOrderList(
    List<Map<String, dynamic>> orders, {
    required String emptyTitle,
    required String emptyDescription,
  }) {
    if (orders.isEmpty) {
      return _buildEmptyState(title: emptyTitle, description: emptyDescription);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isSelling = _tabController.index == 1;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(order['icon'], size: 30, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Order ${order['orderId']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order['date'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                order['price'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(height: 1, color: AppColors.accent.withOpacity(0.25)),

          const SizedBox(height: 12),

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
                        fontSize: 12,
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
                  if (isSelling) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellingOrderDetails(order: order),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BuyingOrderDetails(order: order),
                      ),
                    );
                  }
                },
                child: const Row(
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

  Widget _buildEmptyState({
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
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
