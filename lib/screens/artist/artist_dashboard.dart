import 'package:flutter/material.dart';

import '../../app_theme/artist/artist_colors.dart';
import '../../app_theme/artist/artist_text_styles.dart';
import '../../widgets/artist_more_menu.dart';
import 'buy_products/marketplace.dart';
import 'my_products/add_product.dart';
import 'my_products/selling_orders.dart';

class ArtistHome extends StatefulWidget {
  const ArtistHome({super.key});

  @override
  State<ArtistHome> createState() => _ArtistHomeState();
}

class _ArtistHomeState extends State<ArtistHome> {
  // ============================================================
  // DASHBOARD DATA
  // UI ONLY - WILL BE CONNECTED TO API LATER
  // ============================================================

  final List<Map<String, dynamic>> _stats = [
    {
      'title': 'Total Sales',
      'value': '56',
      'icon': Icons.shopping_bag_outlined,
    },
    {'title': 'Products', 'value': '12', 'icon': Icons.inventory_2_outlined},
    {'title': 'Orders', 'value': '18', 'icon': Icons.receipt_long_outlined},
    {'title': 'Views', 'value': '2,450', 'icon': Icons.visibility_outlined},
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'title': 'Add Product', 'icon': Icons.add_box_outlined, 'type': 'add'},
    {
      'title': 'Marketplace',
      'icon': Icons.storefront_outlined,
      'type': 'marketplace',
    },
    {
      'title': 'My Products',
      'icon': Icons.inventory_2_outlined,
      'type': 'products',
    },
    {'title': 'Orders', 'icon': Icons.receipt_long_outlined, 'type': 'orders'},
    {
      'title': 'Earnings',
      'icon': Icons.account_balance_wallet_outlined,
      'type': 'earnings',
    },
    {'title': 'Reviews', 'icon': Icons.star_outline_rounded, 'type': 'reviews'},
  ];

  final List<Map<String, dynamic>> _recentOrders = [
    {
      'id': '#EL10245',
      'product': 'Upcycled Coffee Table',
      'customer': 'Rahul Patel',
      'price': '₹4,500',
      'status': 'Pending',
      'date': '26 Sep 2026',
    },
    {
      'id': '#EL10244',
      'product': 'Vintage Wall Lamp',
      'customer': 'Priya Shah',
      'price': '₹1,850',
      'status': 'Confirmed',
      'date': '25 Sep 2026',
    },
    {
      'id': '#EL10243',
      'product': 'Recycled Wood Shelf',
      'customer': 'Aarav Mehta',
      'price': '₹2,200',
      'status': 'Processing',
      'date': '24 Sep 2026',
    },
    {
      'id': '#EL10242',
      'product': 'Planter Stand',
      'customer': 'Neha Joshi',
      'price': '₹1,200',
      'status': 'Completed',
      'date': '23 Sep 2026',
    },
  ];

  final List<Map<String, dynamic>> _topProducts = [
    {
      'name': 'Upcycled Coffee Table',
      'category': 'Furniture',
      'price': '₹4,500',
      'sold': '18 sold',
      'views': '324 views',
      'icon': Icons.table_restaurant_outlined,
    },
    {
      'name': 'Vintage Wall Lamp',
      'category': 'Home Decor',
      'price': '₹1,850',
      'sold': '14 sold',
      'views': '268 views',
      'icon': Icons.light_outlined,
    },
    {
      'name': 'Recycled Wood Shelf',
      'category': 'Furniture',
      'price': '₹2,200',
      'sold': '11 sold',
      'views': '215 views',
      'icon': Icons.shelves,
    },
    {
      'name': 'Planter Stand',
      'category': 'Decor',
      'price': '₹1,200',
      'sold': '9 sold',
      'views': '180 views',
      'icon': Icons.yard_outlined,
    },
  ];

  // ============================================================
  // SNACKBAR
  // ============================================================

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
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // QUICK ACTION NAVIGATION
  // ============================================================

  void _handleQuickAction(String type) {
    switch (type) {
      case 'add':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProduct()),
        );
        break;

      case 'marketplace':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Marketplace()),
        );
        break;

      case 'orders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SellingOrders()),
        );
        break;

      case 'earnings':
        _showMessage('Earnings section will be connected later.');
        break;

      case 'products':
        _showMessage('My Products will be connected later.');
        break;

      case 'reviews':
        _showMessage('Reviews will be connected later.');
        break;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 20,
                18,
                isWide ? 32 : 20,
                110,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 22),

                      _buildEarningsCard(),

                      const SizedBox(height: 18),

                      _buildStats(isWide),

                      const SizedBox(height: 30),

                      _buildSectionHeader('Quick Actions', 'Manage your store'),

                      const SizedBox(height: 12),

                      _buildQuickActions(isWide),

                      const SizedBox(height: 30),

                      _buildSectionHeader(
                        'Recent Orders',
                        'View all',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SellingOrders(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildRecentOrders(),

                      const SizedBox(height: 30),

                      _buildSectionHeader(
                        'Top Performing Products',
                        'View all',
                        onTap: () {
                          _showMessage('My Products will be connected later.');
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildTopProducts(),

                      const SizedBox(height: 30),

                      _buildSectionHeader('Performance Overview', 'This Month'),

                      const SizedBox(height: 12),

                      _buildPerformanceCard(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Creative Studio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.heading.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Here is what is happening with your store.',
                style: ArtistTextStyles.caption.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        const ArtistMoreMenu(),
      ],
    );
  }

  // ============================================================
  // EARNINGS CARD
  // ============================================================

  Widget _buildEarningsCard() {
    return InkWell(
      onTap: () {
        _showMessage('Earnings details will be connected later.');
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ArtistColors.surfaceSoft, ArtistColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ArtistColors.border),
          boxShadow: [
            BoxShadow(
              color: ArtistColors.primary.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    style: ArtistTextStyles.label.copyWith(
                      color: ArtistColors.primary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    '₹24,850',
                    style: ArtistTextStyles.heading.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ArtistColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '+12%',
                          style: ArtistTextStyles.caption.copyWith(
                            color: ArtistColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text('from last month', style: ArtistTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ArtistColors.primary, ArtistColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: ArtistColors.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats(bool isWide) {
    if (isWide) {
      return Row(
        children: _stats.map((stat) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: stat == _stats.last ? 0 : 12),
              child: _buildStatCard(stat),
            ),
          );
        }).toList(),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return SizedBox(width: 112, child: _buildStatCard(_stats[index]));
        },
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return InkWell(
      onTap: () {
        _showMessage('${stat['title']} selected.');
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ArtistColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                stat['icon'] as IconData,
                size: 18,
                color: ArtistColors.primary,
              ),
            ),

            const Spacer(),

            Text(
              stat['value'] as String,
              style: ArtistTextStyles.title.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: ArtistColors.primary,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              stat['title'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.small.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        if (onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Text(
                action,
                style: ArtistTextStyles.caption.copyWith(
                  color: ArtistColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(bool isWide) {
    if (isWide) {
      return Row(
        children: _quickActions.map((action) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: action == _quickActions.last ? 0 : 10,
              ),
              child: _buildQuickActionCard(action),
            ),
          );
        }).toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _quickActions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.12,
      ),
      itemBuilder: (context, index) {
        return _buildQuickActionCard(_quickActions[index]);
      },
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action) {
    return InkWell(
      onTap: () {
        _handleQuickAction(action['type'] as String);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ArtistColors.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                action['icon'] as IconData,
                color: ArtistColors.primary,
                size: 21,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              action['title'] as String,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.small.copyWith(
                fontSize: 10.5,
                color: ArtistColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECENT ORDERS
  // ============================================================

  Widget _buildRecentOrders() {
    return Container(
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: List.generate(_recentOrders.length, (index) {
          final order = _recentOrders[index];

          return _buildOrderItem(order, index == _recentOrders.length - 1);
        }),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order, bool isLast) {
    return InkWell(
      onTap: () {
        _showMessage('Order ${order['id']} selected.');
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ArtistColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: ArtistColors.primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['product'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '${order['id']} • ${order['customer']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.small,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order['price'] as String,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    _buildStatusBadge(order['status'] as String),
                  ],
                ),
              ],
            ),

            if (!isLast) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: ArtistColors.border),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: ArtistTextStyles.small.copyWith(
          color: color,
          fontSize: 9.5,
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

  // ============================================================
  // TOP PRODUCTS
  // ============================================================

  Widget _buildTopProducts() {
    return SizedBox(
      height: 215,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _topProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildProductCard(_topProducts[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return InkWell(
      onTap: () {
        _showMessage('${product['name']} selected.');
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ArtistColors.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                product['icon'] as IconData,
                size: 38,
                color: ArtistColors.primary,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              product['name'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 2),

            Text(product['category'] as String, style: ArtistTextStyles.small),

            const Spacer(),

            Row(
              children: [
                Text(
                  product['price'] as String,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Text(
                  product['sold'] as String,
                  style: ArtistTextStyles.small.copyWith(
                    color: ArtistColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PERFORMANCE CARD
  // ============================================================

  Widget _buildPerformanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹24,850',
                      style: ArtistTextStyles.title.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: ArtistColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Total earnings this month',
                      style: ArtistTextStyles.small,
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: ArtistColors.success.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '+12%',
                  style: ArtistTextStyles.small.copyWith(
                    color: ArtistColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 115,
            width: double.infinity,
            child: CustomPaint(painter: _PerformanceChartPainter()),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep']
                .map((month) => Text(month, style: ArtistTextStyles.small))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PERFORMANCE CHART
// ============================================================

class _PerformanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = ArtistColors.border.withOpacity(0.55)
      ..strokeWidth = 1;

    final Paint linePaint = Paint()
      ..color = ArtistColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fillPaint = Paint()
      ..color = ArtistColors.light.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    // Horizontal grid lines
    for (int i = 1; i <= 3; i++) {
      final double y = size.height * i / 4;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<Offset> points = [
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.16, size.height * 0.62),
      Offset(size.width * 0.32, size.height * 0.67),
      Offset(size.width * 0.48, size.height * 0.43),
      Offset(size.width * 0.64, size.height * 0.50),
      Offset(size.width * 0.80, size.height * 0.28),
      Offset(size.width, size.height * 0.18),
    ];

    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final Path fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(linePath, linePaint);

    final Paint pointPaint = Paint()
      ..color = ArtistColors.primary
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
