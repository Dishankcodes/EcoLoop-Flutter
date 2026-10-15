import 'package:flutter/material.dart';

import '../../app_theme/artist/artist_colors.dart';
import '../../app_theme/artist/artist_text_styles.dart';
import '../../services/ecoloop_api.dart';
import '../../widgets/artist_more_menu.dart';
import 'buy_products/marketplace.dart';
import 'my_products/add_product.dart';
import 'my_products/my_product.dart';
import 'my_products/product_analytics.dart';
import 'my_products/selling_orders.dart';
import 'reviews/review_history.dart';

/// Artist dashboard. Business figures and lists are loaded from Code.gs;
/// this screen does not use demonstration orders, products, or analytics.
class ArtistHome extends StatefulWidget {
  const ArtistHome({super.key});

  @override
  State<ArtistHome> createState() => _ArtistHomeState();
}

class _ArtistHomeState extends State<ArtistHome> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _earnings = {};
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _products = [];

  final List<Map<String, dynamic>> _quickActions = const [
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

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value.map(_asMap).where((item) => item.isNotEmpty).toList();
  }

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().replaceAll(',', '')) ?? 0;
  }

  double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '')) ?? 0;
  }

  String _value(dynamic value, {String fallback = ''}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _money(dynamic value) {
    final amount = _double(value);
    final whole = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return '₹${buffer.toString()}';
  }

  String _date(dynamic value) {
    final raw = _value(value);
    if (raw.isEmpty) return 'Date unavailable';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
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
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Future<void> _loadDashboard({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      _error = null;
      if (refresh) {
        _refreshing = true;
      } else {
        _loading = true;
      }
    });

    try {
      // Each endpoint is implemented by the currently supplied Code.gs.
      final results = await Future.wait<dynamic>([
        _api.get('/profile'),
        _api.get('/artist/analytics'),
        _api.get('/artist/analytics/earnings'),
        _api.get('/artist/analytics/products'),
        _api.get('/artist/orders'),
      ]);

      if (!mounted) return;
      setState(() {
        _profile = _asMap(results[0]);
        _analytics = _asMap(results[1]);
        _earnings = _asMap(results[2]);
        _products = _asMapList(results[3]);
        _orders = _asMapList(results[4]);
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String get _artistName => _value(_profile['userName'], fallback: 'Artist');

  int get _sales => _int(_analytics['sales']);

  int get _productCount => _int(_analytics['totalProducts']);

  int get _orderCount => _int(_analytics['totalOrders']);

  int get _views => _int(_analytics['productViews']);

  double get _totalEarnings =>
      _double(_earnings['totalEarnings'] ?? _analytics['revenue']);

  void _showMessage(String message) {
    if (!mounted) return;
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
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadDashboard(refresh: true);
  }

  void _handleQuickAction(String type) {
    switch (type) {
      case 'add':
        _openPage(const AddProduct());
        break;
      case 'marketplace':
        _openPage(const Marketplace());
        break;
      case 'products':
        _openPage(const MyProducts());
        break;
      case 'orders':
        _openPage(const SellingOrders());
        break;
      case 'earnings':
        _openPage(const ProductAnalytics());
        break;
      case 'reviews':
        _openPage(const ReviewHistory());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: ArtistColors.primary),
              )
            : RefreshIndicator(
                color: ArtistColors.primary,
                onRefresh: () => _loadDashboard(refresh: true),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
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
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                _buildErrorBanner(),
                              ],
                              const SizedBox(height: 22),
                              _buildEarningsCard(),
                              const SizedBox(height: 18),
                              _buildStats(isWide),
                              const SizedBox(height: 30),
                              _buildSectionHeader(
                                'Quick Actions',
                                'Manage your store',
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActions(isWide),
                              const SizedBox(height: 30),
                              _buildSectionHeader(
                                'Recent Orders',
                                'View all',
                                onTap: () => _handleQuickAction('orders'),
                              ),
                              const SizedBox(height: 12),
                              _buildRecentOrders(),
                              const SizedBox(height: 30),
                              _buildSectionHeader(
                                'Top Performing Products',
                                'View all',
                                onTap: () => _handleQuickAction('products'),
                              ),
                              const SizedBox(height: 12),
                              _buildTopProducts(),
                              const SizedBox(height: 30),
                              _buildSectionHeader(
                                'Store Overview',
                                'Analytics',
                              ),
                              const SizedBox(height: 12),
                              _buildPerformanceCard(),
                              if (_refreshing) ...[
                                const SizedBox(height: 12),
                                const LinearProgressIndicator(
                                  color: ArtistColors.primary,
                                  minHeight: 2,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: ArtistColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Some dashboard data could not be loaded. $_error',
              style: ArtistTextStyles.small.copyWith(color: ArtistColors.error),
            ),
          ),
          IconButton(
            tooltip: 'Retry',
            onPressed: () => _loadDashboard(refresh: true),
            icon: const Icon(Icons.refresh_rounded, color: ArtistColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $_artistName',
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

  Widget _buildEarningsCard() {
    return InkWell(
      onTap: () => _handleQuickAction('earnings'),
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
                    _money(_totalEarnings),
                    style: ArtistTextStyles.heading.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From recorded paid transactions',
                    style: ArtistTextStyles.caption,
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

  Widget _buildStats(bool isWide) {
    final stats = <Map<String, dynamic>>[
      {
        'title': 'Total Sales',
        'value': _sales.toString(),
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'title': 'Products',
        'value': _productCount.toString(),
        'icon': Icons.inventory_2_outlined,
      },
      {
        'title': 'Orders',
        'value': _orderCount.toString(),
        'icon': Icons.receipt_long_outlined,
      },
      {
        'title': 'Views',
        'value': _views.toString(),
        'icon': Icons.visibility_outlined,
      },
    ];

    if (isWide) {
      return Row(
        children: stats.map((stat) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: stat == stats.last ? 0 : 12),
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
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) =>
            SizedBox(width: 112, child: _buildStatCard(stats[index])),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return InkWell(
      onTap: () {
        final title = stat['title'];
        if (title == 'Orders') {
          _handleQuickAction('orders');
        } else if (title == 'Products' ||
            title == 'Total Sales' ||
            title == 'Views') {
          _handleQuickAction('earnings');
        }
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 112,
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
              stat['value'].toString(),
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
        childAspectRatio: 1.02,
      ),
      itemBuilder: (context, index) =>
          _buildQuickActionCard(_quickActions[index]),
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action) {
    return InkWell(
      onTap: () => _handleQuickAction(action['type'] as String),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ArtistColors.surfaceSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                action['icon'] as IconData,
                color: ArtistColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                action['title'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.small.copyWith(
                  fontSize: 10,
                  color: ArtistColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    if (_orders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        subtitle: 'New orders for your products will appear here.',
        actionLabel: 'Open orders',
        onAction: () => _handleQuickAction('orders'),
      );
    }

    final recent = _orders.take(4).toList();
    return Container(
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: List.generate(recent.length, (index) {
          final order = recent[index];
          return _buildOrderItem(order, index == recent.length - 1);
        }),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order, bool isLast) {
    final orderId = _value(order['orderId'], fallback: '—');
    final product = _value(order['productName'], fallback: 'Product');
    final buyer = _value(order['buyerName'], fallback: 'Buyer');
    final status = _value(order['status'], fallback: 'Unknown');
    final amount =
        order['totalAmount'] ?? order['subtotal'] ?? order['unitPrice'];
    return InkWell(
      onTap: () => _handleQuickAction('orders'),
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
                        product,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '#$orderId • $buyer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.small,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _date(order['createdAt']),
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
                      _money(amount),
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildStatusBadge(status),
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

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _prettyStatus(status),
        style: ArtistTextStyles.small.copyWith(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _prettyStatus(String status) {
    return status
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ArtistColors.warning;
      case 'confirmed':
      case 'shipped':
      case 'out_for_delivery':
        return ArtistColors.info;
      case 'packed':
      case 'processing':
        return ArtistColors.primary;
      case 'delivered':
      case 'completed':
        return ArtistColors.success;
      case 'cancelled':
        return ArtistColors.error;
      default:
        return ArtistColors.textSecondary;
    }
  }

  Widget _buildTopProducts() {
    if (_products.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No product analytics yet',
        subtitle:
            'Your listed products and their performance will appear here.',
        actionLabel: 'Manage products',
        onAction: () => _handleQuickAction('products'),
      );
    }

    final products = List<Map<String, dynamic>>.from(_products)
      ..sort((a, b) => _int(b['salesCount']).compareTo(_int(a['salesCount'])));
    final top = products.take(6).toList();

    return SizedBox(
      height: 235,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: top.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildProductCard(top[index]),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final title = _value(product['title'], fallback: 'Product');
    final status = _value(product['status'], fallback: 'Unknown');
    return InkWell(
      onTap: () => _handleQuickAction('products'),
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
              height: 85,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ArtistColors.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_int(product['views'])} views',
              style: ArtistTextStyles.small,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _money(product['revenue']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${_int(product['salesCount'])} sold',
                  style: ArtistTextStyles.small.copyWith(
                    color: ArtistColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_prettyStatus(status), style: ArtistTextStyles.small),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final followers = _int(_analytics['followers']);
    final reviews = _int(_analytics['reviews']);
    final rating = _double(_analytics['averageRating']);
    final pending = _int(_analytics['pendingOrders']);
    final completed = _int(_analytics['completedOrders']);

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
                      _money(_totalEarnings),
                      style: ArtistTextStyles.title.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: ArtistColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Total recorded earnings',
                      style: ArtistTextStyles.small,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: ArtistColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: ArtistColors.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: ArtistTextStyles.small.copyWith(
                        color: ArtistColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: ArtistColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _overviewMetric(
                  'Followers',
                  followers.toString(),
                  Icons.people_outline,
                ),
              ),
              Expanded(
                child: _overviewMetric(
                  'Reviews',
                  reviews.toString(),
                  Icons.reviews_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _overviewMetric(
                  'Pending orders',
                  pending.toString(),
                  Icons.pending_actions_outlined,
                ),
              ),
              Expanded(
                child: _overviewMetric(
                  'Completed orders',
                  completed.toString(),
                  Icons.task_alt_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ArtistColors.surfaceSoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: ArtistColors.primary),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: ArtistTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ArtistColors.primary,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.small,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: ArtistColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.small.copyWith(
              color: ArtistColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
