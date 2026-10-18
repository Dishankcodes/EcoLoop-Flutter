
import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';

class ProductAnalytics extends StatefulWidget {
  const ProductAnalytics({super.key});

  @override
  State<ProductAnalytics> createState() => _ProductAnalyticsState();
}

class _ProductAnalyticsState extends State<ProductAnalytics> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<String, dynamic> _analytics = <String, dynamic>{};
  List<Map<String, dynamic>> _products = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _inventory = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asRows(dynamic value) {
    dynamic candidate = value;
    if (candidate is Map) {
      final root = _asMap(candidate);
      candidate =
          root['data'] ??
          root['products'] ??
          root['items'] ??
          root['results'] ??
          root['analytics'];
    }
    if (candidate is! List) return <Map<String, dynamic>>[];
    return candidate
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  num _number(dynamic value) {
    if (value is num) return value;
    final cleaned = (value ?? '').toString().replaceAll(',', '').trim();
    return num.tryParse(cleaned) ?? 0;
  }

  String _formattedNumber(num value) {
    final raw = value.round().toString();
    final out = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      out.write(raw[i]);
      final remaining = raw.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) out.write(',');
    }
    return out.toString();
  }

  String _money(dynamic value) => '₹${_formattedNumber(_number(value))}';

  Future<void> _loadAnalytics({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (refresh) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    try {
      // Fetch independent data concurrently to reduce total waiting time.
      // All values come from the authenticated artist's Google Sheets records.
      final responses = await Future.wait<dynamic>([
        _api.get('/artist/analytics'),
        _api.get('/artist/analytics/products'),
        _api.get('/my/products'),
      ]);

      final analytics = _asMap(responses[0]);
      if (analytics.isEmpty) {
        throw const EcoLoopApiException(
          'The backend returned empty product analytics.',
        );
      }

      final products = _asRows(responses[1]);
      final inventory = _asRows(responses[2]);

      products.sort((a, b) {
        final salesCompare = _number(
          b['salesCount'],
        ).compareTo(_number(a['salesCount']));
        if (salesCompare != 0) return salesCompare;
        return _number(b['views']).compareTo(_number(a['views']));
      });

      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _products = products;
        _inventory = inventory;
        _loading = false;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int get _totalProducts => _number(_analytics['totalProducts']).toInt();

  int get _totalViews =>
      _number(_analytics['productViews'] ?? _analytics['totalViews']).toInt();

  int get _totalSales =>
      _number(_analytics['sales'] ?? _analytics['totalSales']).toInt();

  int get _wishlistAdds => _number(
    _analytics['wishlistCount'] ?? _analytics['wishlistAdds'],
  ).toInt();

  int get _pendingOrders => _number(_analytics['pendingOrders']).toInt();

  int get _lowStockItems => _inventory.where((product) {
    final available = _number(
      product['availableQuantity'] ?? product['quantity'],
    );
    final status = (product['status'] ?? '').toString().toLowerCase();
    return status != 'archived' &&
        status != 'sold' &&
        status != 'out_of_stock' &&
        available > 0 &&
        available <= 2;
  }).length;

  num get _earnings =>
      _number(_analytics['revenue'] ?? _analytics['totalEarnings']);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Product Analytics', style: ArtistTextStyles.title),
        actions: [
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: _loading || _refreshing
                ? null
                : () => _loadAnalytics(refresh: true),
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: ArtistColors.primary),
              )
            : (_error != null && _analytics.isEmpty)
            ? Center(
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
                        'Could not load product analytics',
                        textAlign: TextAlign.center,
                        style: ArtistTextStyles.title,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: ArtistTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _loadAnalytics(refresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: ArtistColors.primary,
                onRefresh: () => _loadAnalytics(refresh: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ArtistColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ArtistColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: ArtistColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: ArtistTextStyles.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _loadAnalytics(refresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        'Your Products',
                        style: ArtistTextStyles.title.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _AnalyticsCard(
                              icon: Icons.inventory_2_outlined,
                              value: _formattedNumber(_totalProducts),
                              label: 'Total Products',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AnalyticsCard(
                              icon: Icons.visibility_outlined,
                              value: _formattedNumber(_totalViews),
                              label: 'Total Views',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _AnalyticsCard(
                              icon: Icons.shopping_bag_outlined,
                              value: _formattedNumber(_totalSales),
                              label: 'Total Sales',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AnalyticsCard(
                              icon: Icons.favorite_border_rounded,
                              value: _formattedNumber(_wishlistAdds),
                              label: 'Wishlist Adds',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Performance Overview',
                        style: ArtistTextStyles.title.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ArtistColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: ArtistColors.border),
                        ),
                        child: Column(
                          children: [
                            _PerformanceRow(
                              label: 'Products Sold',
                              value: _formattedNumber(_totalSales),
                              icon: Icons.sell_outlined,
                            ),
                            const Divider(
                              height: 24,
                              color: ArtistColors.border,
                            ),
                            _PerformanceRow(
                              label: 'Pending Orders',
                              value: _formattedNumber(_pendingOrders),
                              icon: Icons.pending_actions_outlined,
                            ),
                            const Divider(
                              height: 24,
                              color: ArtistColors.border,
                            ),
                            _PerformanceRow(
                              label: 'Low Stock Items',
                              value: _formattedNumber(_lowStockItems),
                              icon: Icons.warning_amber_outlined,
                            ),
                            const Divider(
                              height: 24,
                              color: ArtistColors.border,
                            ),
                            _PerformanceRow(
                              label: 'Total Earnings',
                              value: _money(_earnings),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Top Products',
                        style: ArtistTextStyles.title.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 12),
                      if (_products.isNotEmpty) ...[
                        _ProductPerformanceChart(
                          products: _products.take(5).toList(),
                          number: _number,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_products.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: ArtistColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ArtistColors.border),
                          ),
                          child: Text(
                            'No product analytics available yet.',
                            style: ArtistTextStyles.bodyMedium,
                          ),
                        )
                      else
                        ..._products
                            .take(10)
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      entry.key == _products.take(10).length - 1
                                      ? 0
                                      : 10,
                                ),
                                child: _ProductTile(
                                  name:
                                      (entry.value['title'] ??
                                              entry.value['name'] ??
                                              'Untitled product')
                                          .toString(),
                                  views:
                                      '${_formattedNumber(_number(entry.value['views']))} views',
                                  sales:
                                      '${_formattedNumber(_number(entry.value['salesCount']))} sales',
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ANALYTICS CARD
// -----------------------------------------------------------------------------

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),

      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: ArtistColors.primary),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PERFORMANCE ROW
// -----------------------------------------------------------------------------

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ArtistColors.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: ArtistColors.primary),
        ),

        const SizedBox(width: 12),

        Expanded(child: Text(label, style: ArtistTextStyles.bodyMedium)),

        Text(
          value,
          style: ArtistTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: ArtistColors.primary,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// LIVE PRODUCT PERFORMANCE CHART
// -----------------------------------------------------------------------------

class _ProductPerformanceChart extends StatelessWidget {
  const _ProductPerformanceChart({
    required this.products,
    required this.number,
  });

  final List<Map<String, dynamic>> products;
  final num Function(dynamic) number;

  @override
  Widget build(BuildContext context) {
    final maxValue = products.fold<num>(0, (max, product) {
      final views = number(product['views']);
      final sales = number(product['salesCount']);
      return views > max ? views : (sales > max ? sales : max);
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Views & Sales',
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...products.map((product) {
            final title = (product['title'] ?? product['name'] ?? 'Product')
                .toString();
            final views = number(product['views']);
            final sales = number(product['salesCount']);
            final scale = maxValue <= 0 ? 0.0 : 1.0 / maxValue;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.small,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: (views * scale).clamp(0.0, 1.0).toDouble(),
                            backgroundColor: ArtistColors.surfaceSoft,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              ArtistColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 54,
                        child: Text(
                          '${views.round()} views',
                          textAlign: TextAlign.end,
                          style: ArtistTextStyles.small,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: (sales * scale).clamp(0.0, 1.0).toDouble(),
                            backgroundColor: ArtistColors.surfaceSoft,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              ArtistColors.success,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 54,
                        child: Text(
                          '${sales.round()} sales',
                          textAlign: TextAlign.end,
                          style: ArtistTextStyles.small.copyWith(
                            color: ArtistColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ArtistColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text('Views', style: ArtistTextStyles.small),
              const SizedBox(width: 14),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ArtistColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text('Sales', style: ArtistTextStyles.small),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PRODUCT TILE
// -----------------------------------------------------------------------------

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.name,
    required this.views,
    required this.sales,
  });

  final String name;
  final String views;
  final String sales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(views, style: ArtistTextStyles.small),

                    const SizedBox(width: 10),

                    Text(
                      sales,
                      style: ArtistTextStyles.small.copyWith(
                        color: ArtistColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: ArtistColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

