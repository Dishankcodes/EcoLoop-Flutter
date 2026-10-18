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
  String _filter = 'All';
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  double _number(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;

  String _pretty(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');

  String _date(dynamic value) {
    final raw = '${value ?? ''}'.trim();
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
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final status = '${raw['status'] ?? 'new_order'}'.toLowerCase().replaceAll(
      ' ',
      '_',
    );
    final quantity = _number(raw['quantity'] ?? 1).toInt();
    final savedSubtotal =
        raw['subtotal'] ?? raw['lineSubtotal'] ?? raw['productSubtotal'];
    final rawUnitPrice =
        raw['unitPrice'] ?? raw['productPrice'] ?? raw['price'];
    final subtotal = savedSubtotal != null
        ? _number(savedSubtotal)
        : rawUnitPrice != null
        ? _number(rawUnitPrice) * (quantity < 1 ? 1 : quantity)
        : _number(raw['totalAmount'] ?? raw['priceValue']);
    return {
      ...raw,
      'orderId': raw['orderId'] ?? raw['id'] ?? '',
      'product':
          raw['productName'] ??
          raw['title'] ??
          'Product #${raw['productId'] ?? '—'}',
      'priceValue': subtotal,
      'price':
          '₹${subtotal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
      'date': _date(raw['createdAt'] ?? raw['date']),
      'status': status,
      'statusLabel': _pretty(status),
      'buyer':
          raw['buyerName'] ??
          (raw['buyerId'] == null
              ? 'Buyer details unavailable'
              : 'Buyer #${raw['buyerId']}'),
      'quantity': quantity,
      'paymentLabel': _pretty('${raw['paymentStatus'] ?? 'unknown'}'),
    };
  }

  Future<void> _loadOrders() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final data = await EcoLoopApi.instance.get('/selling/orders');
      final dynamic rows = data is List
          ? data
          : data is Map
          ? (data['orders'] ?? data['data'] ?? data['results'] ?? [])
          : [];
      final mapped = rows is List
          ? rows
                .whereType<Map>()
                .map((e) => _normalize(Map<String, dynamic>.from(e)))
                .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _orders = mapped;
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

  List<Map<String, dynamic>> get _visibleOrders {
    final query = _search.text.trim().toLowerCase();
    return _orders.where((order) {
      final status = '${order['status']}';
      final statusMatch =
          _filter == 'All' ||
          (_filter == 'Active' &&
              !['delivered', 'completed', 'cancelled'].contains(status)) ||
          (_filter == 'Completed' &&
              ['delivered', 'completed'].contains(status)) ||
          (_filter == 'Cancelled' && status == 'cancelled');
      final searchMatch =
          query.isEmpty ||
          '${order['product']}'.toLowerCase().contains(query) ||
          '${order['orderId']}'.toLowerCase().contains(query) ||
          '${order['buyer']}'.toLowerCase().contains(query);
      return statusMatch && searchMatch;
    }).toList();
  }

  double get _gross => _orders
      .where((o) => '${o['status']}' != 'cancelled')
      .fold<double>(
        0,
        (sum, o) =>
            sum + _number(o['subtotal'] ?? o['totalAmount'] ?? o['priceValue']),
      );

  double get _pending => _orders
      .where(
        (o) =>
            !['delivered', 'completed', 'cancelled'].contains('${o['status']}'),
      )
      .fold<double>(
        0,
        (sum, o) =>
            sum + _number(o['subtotal'] ?? o['totalAmount'] ?? o['priceValue']),
      );

  int get _completed => _orders
      .where((o) => ['delivered', 'completed'].contains('${o['status']}'))
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        children: const [
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
                            retry: _loadOrders,
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
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 28),
                        children: [
                          _summaryCard(),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search product, buyer or order ID',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppColors.accent.withOpacity(.4),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppColors.accent.withOpacity(.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  ['All', 'Active', 'Completed', 'Cancelled']
                                      .map(
                                        (f) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(f),
                                            selected: _filter == f,
                                            onSelected: (_) =>
                                                setState(() => _filter = f),
                                            selectedColor: AppColors.light,
                                            labelStyle: TextStyle(
                                              color: _filter == f
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            side: BorderSide(
                                              color: _filter == f
                                                  ? AppColors.primary
                                                  : AppColors.accent
                                                        .withOpacity(.4),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Order History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${_visibleOrders.length} orders',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_visibleOrders.isEmpty)
                            _message(
                              Icons.search_off_rounded,
                              'No matching orders',
                              'Try another search or filter.',
                            )
                          else
                            ..._visibleOrders.map(_orderCard),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 5),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selling Orders',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Manage orders from your buyers',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primary.withOpacity(.82)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(.16),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Selling Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'SELLER HUB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          '₹${_gross.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const Text(
          'Non-cancelled order value',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 18),
        Divider(height: 1, color: Colors.white.withOpacity(.22)),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _summaryMetric(
                Icons.receipt_long_outlined,
                'Orders',
                '${_orders.length}',
              ),
            ),
            Container(
              height: 38,
              width: 1,
              color: Colors.white.withOpacity(.2),
            ),
            Expanded(
              child: _summaryMetric(
                Icons.check_circle_outline_rounded,
                'Completed',
                '$_completed',
              ),
            ),
            Container(
              height: 38,
              width: 1,
              color: Colors.white.withOpacity(.2),
            ),
            Expanded(
              child: _summaryMetric(
                Icons.schedule_rounded,
                'In progress',
                '₹${_pending.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _summaryMetric(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Row(
      children: [
        Icon(icon, size: 17, color: Colors.white70),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
    final color = ['delivered', 'completed'].contains(status)
        ? AppColors.success
        : status == 'cancelled'
        ? AppColors.error
        : status == 'packed'
        ? Colors.orange
        : AppColors.primary;
    final image = '${order['productImage'] ?? ''}'.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.accent.withOpacity(.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 70,
                width: 70,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        size: 30,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order['product']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Order #${order['orderId']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order['date']}',
                      style: const TextStyle(
                        fontSize: 11,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty ${order['quantity']}',
                    style: const TextStyle(
                      fontSize: 10,
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
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${order['statusLabel']}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                'Payment: ${order['paymentLabel']}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellingOrderDetails(order: order),
                      ),
                    ).then((changed) {
                      if (changed == true) _loadOrders();
                    }),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('View details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String body, {
    Future<void> Function()? retry,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 80, 28, 30),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 50, color: AppColors.primary),
        const SizedBox(height: 15),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        if (retry != null) ...[
          const SizedBox(height: 15),
          OutlinedButton(onPressed: retry, child: const Text('Try again')),
        ],
      ],
    ),
  );
}
