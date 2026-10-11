import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ecoloop/services/ecoloop_api.dart';
import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import 'order_tracking.dart';
import 'buying_order_details.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});
  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await EcoLoopApi.instance.get('/orders');
      final rows = data is List
          ? data.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() { _orders = rows; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse((value ?? '').toString()) ?? 0;
  String _money(dynamic value) => '₹${_number(value).round()}';
  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Date unavailable';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final date = parsed.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
  String _pretty(dynamic value) {
    final text = (value ?? 'pending').toString().replaceAll('_', ' ').toLowerCase();
    return text.split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return AppColors.success;
      case 'cancelled': return Colors.red;
      case 'shipped':
      case 'out for delivery': return Colors.orange;
      default: return AppColors.primary;
    }
  }
  Map<String, dynamic> _normalizedOrder(Map<String, dynamic> order) {
    dynamic address = order['shippingAddress'] ?? order['address'];
    if (address is String) {
      try { final decoded = jsonDecode(address); if (decoded is Map) address = Map<String, dynamic>.from(decoded); } catch (_) { /* keep original address */ }
    }
    return {
      ...order,
      'product': order['productName'] ?? order['title'] ?? order['product'] ?? 'Product',
      'price': _money(order['totalAmount'] ?? order['amount']),
      'date': _date(order['createdAt'] ?? order['orderDate']),
      'orderId': order['orderId'] ?? '',
      'status': _pretty(order['status']),
      'payment': _pretty(order['paymentMethod']),
      'paymentStatus': _pretty(order['paymentStatus']),
      'address': address,
    };
  }
  void _openDetails(Map<String, dynamic> order) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BuyingOrderDetails(order: _normalizedOrder(order))));
  }
  void _openTracking(Map<String, dynamic> order) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTracking(order: _normalizedOrder(order))));
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 44, color: AppColors.primary),
        const SizedBox(height: 12),
        Text('Could not load orders\n$_error', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ])));
    } else if (_orders.isEmpty) {
      body = ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.receipt_long_outlined, size: 58, color: AppColors.primary),
        const SizedBox(height: 14),
        Text('No orders yet', textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Your purchases will appear here when you place an order.', textAlign: TextAlign.center, style: AppTextStyles.body),
      ]);
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: _orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _orderCard(_orders[index]),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, foregroundColor: AppColors.textPrimary, elevation: 0, title: Text('My Orders', style: AppTextStyles.title), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh orders')]),
      body: RefreshIndicator(onRefresh: _load, child: body is ListView ? body : ListView(physics: const AlwaysScrollableScrollPhysics(), children: [SizedBox(height: MediaQuery.of(context).size.height * .65, child: body)])),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final normalized = _normalizedOrder(order);
    final status = normalized['status'].toString();
    final color = _statusColor(status);
    final title = normalized['product'].toString();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.accent.withValues(alpha: .45))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Order #${normalized['orderId']}', style: AppTextStyles.caption),
            Text(normalized['date'].toString(), style: AppTextStyles.caption),
          ])),
          const SizedBox(width: 8),
          Text(_money(order['totalAmount'] ?? order['amount']), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        ]),
        const SizedBox(height: 13),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(child: Text('Payment: ${normalized['paymentStatus']}', style: AppTextStyles.caption)),
          Text('Qty ${order['quantity'] ?? 1}', style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _openDetails(order), child: const Text('Details'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: () => _openTracking(order), child: const Text('Track order'))),
        ]),
      ]),
    );
  }
}
