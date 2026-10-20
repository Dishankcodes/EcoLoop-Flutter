import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';

class SellersEarning extends StatefulWidget {
  const SellersEarning({super.key});

  @override
  State<SellersEarning> createState() => _SellersEarningState();
}

class _SellersEarningState extends State<SellersEarning> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _products = [];
  String _filter = 'All';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}'.replaceAll(',', '')) ?? 0;
  }

  String _money(dynamic value) {
    final amount = _number(value);
    return '₹${amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '')}';
  }

  List<Map<String, dynamic>> _rows(dynamic value) {
    dynamic source = value;
    if (source is Map) {
      source =
          source['products'] ??
          source['data'] ??
          source['items'] ??
          source['results'] ??
          [];
      if (source is Map) source = source['products'] ?? source['items'] ?? [];
    }
    if (source is! List) return [];
    return source.whereType<Map>().map((row) {
      return Map<String, dynamic>.from(row);
    }).toList();
  }

  Future<void> _loadEarnings() async {
    // Keep earnings visible during a refresh when a previous result exists.
    if (mounted && _summary.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _error = null);
    }
    try {
      final response = await EcoLoopApi.instance.get('/selling/earnings');
      if (response is! Map) {
        throw Exception(
          'The earnings service returned an unexpected response.',
        );
      }
      final data = Map<String, dynamic>.from(response);
      if (data['data'] is Map) {
        data.addAll(Map<String, dynamic>.from(data['data'] as Map));
      }
      if (!mounted) return;
      setState(() {
        _summary = data;
        _products = _rows(data['products']);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleProducts {
    final query = _search.trim().toLowerCase();
    return _products.where((product) {
      final name = '${product['productName'] ?? ''}'.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          '${product['productId'] ?? ''}'.contains(query);
      final net = _number(product['netEarnings']);
      final pending = _number(product['pendingEarnings']);
      final matchesFilter =
          _filter == 'All' ||
          (_filter == 'Earning' && net > 0) ||
          (_filter == 'Pending' && pending > 0);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seller Earnings'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Refresh earnings',
            onPressed: _loadEarnings,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        child: _loading && _summary.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadEarnings,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    if (_error != null) _errorBanner(),
                    _buildHero(),
                    const SizedBox(height: 15),
                    _buildMetricGrid(),
                    const SizedBox(height: 22),
                    _buildProductHeader(),
                    const SizedBox(height: 12),
                    _buildSearch(),
                    const SizedBox(height: 11),
                    _buildFilters(),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_visibleProducts.isEmpty)
                      _emptyProducts()
                    else
                      ..._visibleProducts.map(_productCard),
                    const SizedBox(height: 15),
                    _buildProfitNote(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Last updated ${_dateOnly(_summary['updatedAt'])}',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHero() {
    final net = _number(_summary['totalNetEarnings']);
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174D36), Color(0xFF2D7652)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF174D36).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Sales overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Your net earnings',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _money(net),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Product sales minus EcoLoop platform fees',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 17),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white70,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${_summary['unitsSold'] ?? 0} units sold',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              Text(
                '${_summary['completedOrders'] ?? 0} completed orders',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: 'Gross sales',
                value: _money(_summary['totalGrossSales']),
                icon: Icons.shopping_bag_outlined,
                tint: const Color(0xFFE8F2EA),
                iconColor: const Color(0xFF276749),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _metricCard(
                title: 'Platform fees',
                value: _money(_summary['totalPlatformFees']),
                icon: Icons.receipt_long_outlined,
                tint: const Color(0xFFFFF0E3),
                iconColor: const Color(0xFFB86B22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: 'Pending earnings',
                value: _money(_summary['pendingEarnings']),
                icon: Icons.hourglass_top_rounded,
                tint: const Color(0xFFFFF5D9),
                iconColor: const Color(0xFF94721A),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _metricCard(
                title: 'Products sold',
                value: '${_summary['unitsSold'] ?? 0}',
                icon: Icons.inventory_2_outlined,
                tint: const Color(0xFFE9ECFA),
                iconColor: const Color(0xFF4E5CA5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color tint,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 13),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product-wise earnings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'See sales, fees and net earnings for each item.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${_products.length} items',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) => setState(() => _search = value),
      decoration: InputDecoration(
        hintText: 'Search a product...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      children: ['All', 'Earning', 'Pending'].map((label) {
        final selected = _filter == label;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => setState(() => _filter = label),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          side: BorderSide(
            color: selected
                ? AppColors.primary
                : AppColors.accent.withOpacity(0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
  }

  Widget _productCard(Map<String, dynamic> item) {
    final gross = _number(item['grossSales']);
    final fee = _number(item['platformFees']);
    final net = _number(item['netEarnings']);
    final pending = _number(item['pendingEarnings']);
    final image = '${item['productImage'] ?? ''}'.trim();
    final title = '${item['productName'] ?? 'Untitled product'}';
    final quantity = item['unitsSold'] ?? 0;
    final id = item['productId'] ?? '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 65,
                  height: 65,
                  color: AppColors.light,
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Product ID: $id  •  $quantity units sold',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 13,
                          color: Color(0xFF32825A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item['completedOrders'] ?? 0} completed',
                          style: const TextStyle(
                            color: Color(0xFF32825A),
                            fontSize: 10.5,
                          ),
                        ),
                        if ((item['pendingOrders'] ?? 0) != 0) ...[
                          const SizedBox(width: 9),
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: Color(0xFFB07822),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${item['pendingOrders']} pending',
                            style: const TextStyle(
                              color: Color(0xFFB07822),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net earnings',
                        style: TextStyle(
                          color: Color(0xFF54705E),
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _money(net),
                        style: const TextStyle(
                          color: Color(0xFF185B39),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFFD6E5D9)),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Pending',
                        style: TextStyle(
                          color: Color(0xFF8A6C27),
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _money(pending),
                        style: const TextStyle(
                          color: Color(0xFF8A6C27),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          _moneyLine('Gross product sales', _money(gross)),
          const SizedBox(height: 7),
          _moneyLine(
            'EcoLoop platform fees',
            '− ${_money(fee)}',
            valueColor: const Color(0xFFB66A35),
          ),
          const SizedBox(height: 7),
          _moneyLine(
            'Estimated profit before your own costs',
            _money(net),
            bold: true,
          ),
          if ('${item['lastSaleAt'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              'Latest order: ${_dateOnly(item['lastSaleAt'])}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _moneyLine(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF0DEBC)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF966D25), size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Profit shown here is an estimate: product sales minus platform fees. Your purchase, repair, packaging or refurbishment costs are not recorded in the current system, so they cannot yet be deducted.',
              style: TextStyle(
                color: Color(0xFF765B2A),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1CACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFF8F1C16), fontSize: 12),
            ),
          ),
          TextButton(onPressed: _loadEarnings, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _emptyProducts() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F2EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.query_stats_rounded,
              color: Color(0xFF276749),
              size: 30,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'No earnings to show yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'When buyers place orders for your listed products, their sales and earnings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _dateOnly(dynamic value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text == 'null') return '—';
    final normalized = text.replaceFirst('T', ' ');
    final parts = normalized.split(' ');
    return parts.first;
  }
}
