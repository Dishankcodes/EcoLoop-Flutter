import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ecoloop/services/ecoloop_api.dart';
import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../reviews/product_reviews.dart';
import '../reviews/seller_reviews.dart';
import 'buying_order_details.dart';
import 'order_tracking.dart';

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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await EcoLoopApi.instance.get('/orders');
      final rows = data is List ? data.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList() : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() { _orders = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double _number(dynamic v) => v is num ? v.toDouble() : double.tryParse((v ?? '').toString()) ?? 0;
  String _money(dynamic v) => '₹${_number(v).round()}';
  String _date(dynamic v) {
    if (v == null || v.toString().isEmpty) return 'Date unavailable';
    final d = DateTime.tryParse(v.toString());
    if (d == null) return v.toString();
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${_month(local.month)} ${local.year}';
  }
  String _month(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
  String _status(String? s) {
    final v = (s ?? 'pending').toLowerCase().replaceAll('_', ' ');
    return v.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'delivered') return AppColors.success;
    if (s == 'cancelled') return Colors.red;
    if (s == 'shipped' || s == 'out for delivery') return Colors.orange;
    return AppColors.primary;
  }
  Map<String, dynamic> _trackingData(Map<String, dynamic> o) {
    dynamic address = o['shippingAddress'];
    if (address is String) { try { address = jsonDecode(address); } catch (_) {} }
    return {...o, 'product': o['productName'] ?? '', 'price': _money(o['totalAmount']), 'date': _date(o['createdAt']), 'orderId': '#ECO-${o['orderId']}', 'status': _status(o['status']?.toString()), 'address': address};
  }
  void _openTracking(Map<String, dynamic> order) => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTracking(order: _trackingData(order))));
  void _openDetails(Map<String, dynamic> order) => Navigator.push(context, MaterialPageRoute(builder: (_) => BuyingOrderDetails(order: _trackingData(order))));

  void _openProductReview(Map<String, dynamic> order) {
    final product = <String, dynamic>{'productId': order['productId'], 'title': order['productName'], 'image': order['productImage']};
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductReviews(product: product, orderId: order['orderId']?.toString())));
  }
  void _openSellerReview(Map<String, dynamic> order) {
    final sellerName = (order['sellerName'] ?? '').toString().trim();
    Navigator.push(context, MaterialPageRoute(builder: (_) => SellerReviews(
      sellerId: order['sellerId']?.toString() ?? '',
      sellerType: order['sellerType']?.toString() ?? 'user',
      sellerName: sellerName.isEmpty ? 'Seller' : sellerName,
      orderId: order['orderId']?.toString(),
    )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(backgroundColor: AppColors.background, foregroundColor: AppColors.textPrimary, elevation: 0, title: Text('My Orders', style: AppTextStyles.title), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: RefreshIndicator(onRefresh: _load, child: _loading
      ? ListView(children: [const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()))])
      : _error != null
        ? ListView(padding: const EdgeInsets.all(24), children: [const Icon(Icons.cloud_off_outlined, size: 42), const SizedBox(height: 12), Text('Could not load orders\n$_error', textAlign: TextAlign.center), const SizedBox(height: 12), Center(child: FilledButton(onPressed: _load, child: const Text('Retry')))])
        : _orders.isEmpty
          ? ListView(padding: const EdgeInsets.all(28), children: [const SizedBox(height: 70), const Icon(Icons.receipt_long_outlined, size: 58, color: AppColors.primary), const SizedBox(height: 14), Text('No orders yet', textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 20)), const SizedBox(height: 6), Text('Orders you place will appear here from your EcoLoop account.', textAlign: TextAlign.center, style: AppTextStyles.body)])
          : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), itemCount: _orders.length, separatorBuilder: (_, index) => const SizedBox(height: 12), itemBuilder: (context, index) => _orderCard(_orders[index]))),
  );

  Widget _orderCard(Map<String, dynamic> o) {
    final status = _status(o['status']?.toString());
    final color = _statusColor(status);
    final title = (o['productName'] ?? '').toString();
    final id = o['orderId']?.toString() ?? '';
    final delivered = status.toLowerCase() == 'delivered';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.accent.withValues(alpha: .45))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.isEmpty ? 'Product' : title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4), Text('Order #$id', style: AppTextStyles.caption), Text(_date(o['createdAt']), style: AppTextStyles.caption),
          ])),
          Text(_money(o['totalAmount']), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        ]),
        const SizedBox(height: 13),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
          const SizedBox(width: 8), Expanded(child: Text('Payment: ${_status(o['paymentStatus']?.toString())}', style: AppTextStyles.caption)), Text('Qty ${o['quantity'] ?? 1}', style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _openDetails(o), child: const Text('Details'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: () => _openTracking(o), child: const Text('Track order'))),
        ]),
        if (delivered) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _openProductReview(o), icon: const Icon(Icons.rate_review_outlined, size: 17), label: const Text('Review product'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => _openSellerReview(o), icon: const Icon(Icons.person_outline, size: 17), label: const Text('Review seller'))),
          ]),
        ],
      ]),
    );
  }
}
