import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'selling_order_details.dart';

class SellingOrders extends StatefulWidget {
  const SellingOrders({super.key});

  @override
  State<SellingOrders> createState() => _SellingOrdersState();
}

class _SellingOrdersState extends State<SellingOrders> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final data = await EcoLoopApi.instance.get('/artist/orders');
      final rows = data is List
          ? data
          : (data is Map && data['orders'] is List
                ? data['orders'] as List
                : <dynamic>[]);
      final mapped = rows
          .whereType<Map>()
          .map((e) => _normalize(Map<String, dynamic>.from(e)))
          .toList();
      if (mounted)
        setState(() {
          _orders = mapped;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
    }
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final amount = _num(raw['totalAmount'] ?? raw['price'] ?? raw['amount']);
    final created = DateTime.tryParse(
      '${raw['createdAt'] ?? raw['date'] ?? ''}',
    );
    final status = _prettyStatus('${raw['status'] ?? 'new_order'}');
    return {
      ...raw,
      'orderId': raw['orderId'] ?? raw['id'] ?? '',
      'product':
          raw['productName'] ??
          raw['title'] ??
          'Product #${raw['productId'] ?? '—'}',
      'priceValue': amount,
      'price':
          '₹${amount.toStringAsFixed(2).replaceAll(RegExp(r'\\.00$'), '')}',
      'date': created == null
          ? 'Date unavailable'
          : '${created.day.toString().padLeft(2, '0')} ${_month(created.month)} ${created.year}',
      'status': status,
      'buyer':
          raw['buyerName'] ??
          (raw['buyerId'] == null
              ? 'Buyer details unavailable'
              : 'Buyer #${raw['buyerId']}'),
      'quantity': raw['quantity'] ?? 1,
      'payment': _prettyStatus('${raw['paymentStatus'] ?? 'unknown'}'),
      'icon': Icons.inventory_2_outlined,
    };
  }

  double _num(dynamic v) => double.tryParse('$v') ?? 0;

  String _month(int m) => const [
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
  ][m - 1];

  String _prettyStatus(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .where((x) => x.isNotEmpty)
      .map((x) => x[0].toUpperCase() + x.substring(1).toLowerCase())
      .join(' ');

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          _header(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child: _loading
                  ? ListView(
                      children: [
                        SizedBox(height: 180),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null
                  ? ListView(
                      children: [
                        _message(
                          Icons.cloud_off_outlined,
                          'Could not load selling orders',
                          _error!,
                          onRetry: _loadOrders,
                        ),
                      ],
                    )
                  : _orders.isEmpty
                  ? ListView(
                      children: [
                        _message(
                          Icons.storefront_outlined,
                          'No sales yet',
                          'Orders for your products will appear here when buyers place them.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        _summaryCard(),
                        const SizedBox(height: 24),
                        Row(
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
                            Text(
                              '${_orders.length} orders',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._orders.map(_orderCard),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selling Orders',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage orders from your buyers',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

  Widget _summaryCard() {
    final total = _orders.fold<double>(
      0,
      (s, o) => s + _num(o['totalAmount'] ?? o['priceValue']),
    );
    final pending = _orders
        .where(
          (o) => !['Delivered', 'Completed', 'Cancelled'].contains(o['status']),
        )
        .fold<double>(
          0,
          (s, o) => s + _num(o['totalAmount'] ?? o['priceValue']),
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(.82)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Selling Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Text(
            'Total order value',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: Colors.white.withOpacity(.2)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _earning(
                  'Orders',
                  '${_orders.length}',
                  Icons.receipt_long_outlined,
                ),
              ),
              Container(
                height: 38,
                width: 1,
                color: Colors.white.withOpacity(.18),
              ),
              Expanded(
                child: _earning(
                  'In progress',
                  '₹${pending.toStringAsFixed(2)}',
                  Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earning(String label, String value, IconData icon) => Padding(
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
                label,
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

  Widget _orderCard(Map<String, dynamic> order) {
    final status = '${order['status']}';
    final color = ['Delivered', 'Completed'].contains(status)
        ? AppColors.success
        : status == 'Cancelled'
        ? AppColors.error
        : status == 'Packed'
        ? Colors.orange
        : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.accent.withOpacity(.45)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 31,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order['product']}',
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
                      'Order #${order['orderId']}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order['date']}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order['price']}',
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
          Divider(height: 1, color: AppColors.accent.withOpacity(.25)),
          const SizedBox(height: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellingOrderDetails(order: order),
                    ),
                  ).then((changed) {
                    if (changed == true) _loadOrders();
                  }),
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String body, {
    Future<void> Function()? onRetry,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 100, 28, 30),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 52, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ],
    ),
  );
}
